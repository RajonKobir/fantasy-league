<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Jobs\SendVerificationEmailJob;
use App\Jobs\SendVerificationCodeEmailJob;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Str;

class AuthController extends Controller
{
    public function register(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|email',
            'password' => 'required|string|min:6|confirmed',
        ]);

        // Check if email exists and is already verified
        $existingUser = User::where('email', $validated['email'])->first();
        if ($existingUser && $existingUser->email_verified_at !== null) {
            return response()->json(
                ['message' => 'Email already registered. Please log in or use another email.'],
                422
            );
        }

        // If unverified user exists with this email, delete and recreate
        if ($existingUser && $existingUser->email_verified_at === null) {
            $existingUser->delete();
        }

        $user = User::create([
            'name' => $validated['name'],
            'email' => $validated['email'],
            'password' => bcrypt($validated['password']),
        ]);

        // Fire the Registered event so a verification email can be sent
        event(new \Illuminate\Auth\Events\Registered($user));

        return response()->json(['message' => 'Registered. Please check your email to verify your account.'], 201);
    }

    public function login(Request $request)
    {
        // Require an email address (no username fallback)
        $request->validate([
            'email' => 'required|email',
            'password' => 'required',
        ]);

        $login = $request->input('email');

        $user = User::where('email', $login)->first();

        if (! $user || ! Hash::check($request->password, $user->password)) {
            return response()->json(['message' => 'Invalid credentials'], 401);
        }

        // Require email verification before login
        if (empty($user->email_verified_at)) {
            return response()->json(['message' => 'Email address not verified'], 403);
        }

        // Optionally revoke previous tokens
        $user->tokens()->delete();

        $token = $user->createToken('mobile')->plainTextToken;

        return response()->json(['user' => $user, 'token' => $token]);
    }

    public function logout(Request $request)
    {
        try {
            $user = $request->user();
            if (!$user) {
                return response()->json(['message' => 'User not authenticated'], 401);
            }

            $token = $user->currentAccessToken();
            if ($token) {
                $token->delete();
            }

            return response()->json(['message' => 'Logged out successfully']);
        } catch (\Exception $e) {
            return response()->json(['message' => 'Logout failed', 'error' => $e->getMessage()], 500);
        }
    }

    public function user(Request $request)
    {
        return response()->json($request->user());
    }

    /**
     * Social login endpoint
     * Accepts: provider (facebook|google), token (access_token or id_token)
     * Verifies token with provider and finds or creates a user, returns sanctum token.
     */
    public function socialLogin(Request $request)
    {
        $request->validate([
            'provider' => 'required|in:facebook,google',
            'token' => 'required|string',
        ]);

        $provider = $request->provider;
        $token = $request->token;

        $email = null;
        $name = null;
        $avatar = null;

        if ($provider === 'facebook') {
            // Query Facebook Graph API for profile info
            $resp = Http::get('https://graph.facebook.com/me', [
                'fields' => 'id,name,email,picture',
                'access_token' => $token,
            ]);
            if ($resp->failed()) {
                return response()->json(['message' => 'Invalid facebook token'], 401);
            }
            $data = $resp->json();
            $email = $data['email'] ?? null;
            $name = $data['name'] ?? null;
            $avatar = $data['picture']['data']['url'] ?? null;
            $socialId = $data['id'] ?? null;
        } else {
            // Google: verify id_token
            $resp = Http::get('https://oauth2.googleapis.com/tokeninfo', [
                'id_token' => $token,
            ]);
            if ($resp->failed()) {
                return response()->json(['message' => 'Invalid google token'], 401);
            }
            $data = $resp->json();
            $email = $data['email'] ?? null;
            $name = $data['name'] ?? null;
            $avatar = $data['picture'] ?? null;
            $socialId = $data['sub'] ?? null;
        }

        if (empty($email)) {
            // Fallback email to a provider-scoped placeholder
            $email = $provider.'_'.($socialId ?? Str::random(8)).'@noemail.local';
        }

        // Find existing user by email or create new
        $user = User::where('email', $email)->first();
        if (! $user) {
            $user = User::create([
                'name' => $name ?? 'User',
                'email' => $email,
                // store a random password for social accounts
                'password' => bcrypt(Str::random(24)),
            ]);
            // set avatar if column exists
            if (! empty($avatar) && Schema::hasColumn('users', 'avatar_url')) {
                $user->avatar_url = $avatar;
            }
            // Mark email verified if provider provided an email
            if ($data['email'] ?? false) {
                $user->email_verified_at = now();
            }
            $user->save();
        } else {
            // update any profile fields from provider
            $updated = false;
            if ($name && $user->name !== $name) {
                $user->name = $name;
                $updated = true;
            }
            if (! empty($avatar) && Schema::hasColumn('users', 'avatar_url') && $user->avatar_url !== $avatar) {
                $user->avatar_url = $avatar;
                $updated = true;
            }
            if ($updated) {
                $user->save();
            }
        }

        // Revoke previous tokens and create a new one
        $user->tokens()->delete();
        $token = $user->createToken('mobile')->plainTextToken;

        return response()->json(['user' => $user, 'token' => $token]);
    }

    /**
     * Verify email using a verification code sent to the user's email
     * Expects: { email, token } where token is the hash from the email link
     */
    public function verifyEmail(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'token' => 'required|string',
        ]);

        $email = $request->email;
        $token = $request->token;

        // Find user by current email or pending email
        $user = User::where('email', $email)->orWhere('email_pending', $email)->first();

        if (!$user) {
            return response()->json(['message' => 'User not found'], 404);
        }

        // Determine if this is a pending email verification or initial email verification
        $isPendingEmail = $email === $user->email_pending;

        if ($isPendingEmail) {
            // Verifying a NEW email address from profile update
            Log::info('[VerifyEmail] Verifying pending email for user: ' . $user->id);
            $hashedToken = hash('sha256', $user->getKey() . $user->email_pending);

            if (!hash_equals($token, $hashedToken)) {
                return response()->json(['message' => 'Invalid verification token'], 401);
            }

            // Update current email to the pending email and mark as verified
            $user->email = $user->email_pending;
            $user->email_pending = null;
            $user->email_verified_at = now();
            $user->save();

            Log::info('[VerifyEmail] Email confirmed and updated to: ' . $user->email);
            return response()->json(['message' => 'Email verified and updated successfully'], 200);
        } else {
            // Verifying initial email (from registration)
            Log::info('[VerifyEmail] Verifying initial email for user: ' . $user->id);

            if ($user->email_verified_at !== null) {
                return response()->json(['message' => 'Email already verified'], 200);
            }

            $hashedToken = hash('sha256', $user->getKey() . $email);

            if (!hash_equals($token, $hashedToken)) {
                return response()->json(['message' => 'Invalid verification token'], 401);
            }

            // Mark email as verified
            $user->email_verified_at = now();
            $user->save();

            return response()->json(['message' => 'Email verified successfully'], 200);
        }
    }

    /**
     * Resend verification email to unverified user
     */
    public function resendVerificationEmail(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
        ]);

        $user = User::where('email', $request->email)->first();

        if (! $user) {
            return response()->json(['message' => 'User not found'], 404);
        }

        if ($user->email_verified_at !== null) {
            return response()->json(['message' => 'Email already verified'], 200);
        }

        // Resend the verification code (app expects a code, not a signed URL)
        try {
            $token = hash('sha256', $user->getKey() . $user->email);
            SendVerificationCodeEmailJob::dispatch($user->email, $token);
            Log::info('[ResendVerification] Queued verification code email to: ' . $user->email);
        } catch (\Exception $e) {
            Log::error('[ResendVerification] Failed to queue verification email: ' . $e->getMessage());
            return response()->json(['message' => 'Failed to send verification email'], 500);
        }

        return response()->json(['message' => 'Verification code sent'], 200);
    }

    /**
     * Update authenticated user's profile (name, email, avatar)
     */
    public function updateProfile(Request $request)
    {
        $user = $request->user();

        if (!$user) {
            return response()->json(['message' => 'Unauthorized'], 401);
        }

        Log::info('[UpdateProfile] Request method: ' . $request->getMethod());
        Log::info('[UpdateProfile] Content-Type: ' . $request->header('Content-Type'));
        Log::info('[UpdateProfile] All request data: ' . json_encode($request->all()));

        try {
            $validated = $request->validate([
                'name' => 'nullable|string|max:255',
                'email' => 'nullable|email|unique:users,email,'.$user->id,
                'avatar' => 'nullable|image|max:5120', // 5MB max
            ]);
            Log::info('[UpdateProfile] Validation passed');
        } catch (\Illuminate\Validation\ValidationException $e) {
            Log::error('[UpdateProfile] Validation failed: ' . json_encode($e->errors()));
            throw $e;
        }

        // Track if email changed for verification
        $emailChanged = isset($validated['email']) && $validated['email'] !== $user->email;

        // Cache old avatar path for potential cleanup after successful update
        // Use getAttributes() to get raw path without accessor transformation
        $oldAvatarPath = null;
        $rawAvatarUrl = $user->getAttributes()['avatar_url'] ?? null;
        if ($rawAvatarUrl) {
            $oldAvatarPath = $rawAvatarUrl;
        }

        DB::beginTransaction();
        try {
            // Update name if provided
            if (isset($validated['name'])) {
                Log::info('[UpdateProfile] Updating name to: ' . $validated['name']);
                $user->name = $validated['name'];
            }

            // If email is changed, store it in pending field instead of updating directly
            // The email will only be updated after verification
            if (isset($validated['email']) && $validated['email'] !== $user->email) {
                Log::info('[UpdateProfile] Storing pending email to: ' . $validated['email']);
                $user->email_pending = $validated['email'];
            }

            // Handle avatar upload
            $avatarPath = null;
            if ($request->hasFile('avatar')) {
                Log::info('[UpdateProfile] Uploading avatar');
                $avatarFile = $request->file('avatar');
                $avatarPath = $avatarFile->storeAs(
                    'avatars/' . $user->id,
                    $avatarFile->hashName(),
                    'public'
                );
                // Store only the relative path (without /storage/). The accessor will add the full URL
                $user->avatar_url = $avatarPath;
                Log::info('[UpdateProfile] Avatar stored at: ' . $avatarPath);
            }

            Log::info('[UpdateProfile] User state before save - name: ' . $user->name . ', email: ' . $user->email . ', email_pending: ' . ($user->email_pending ?? 'null'));
            $user->save();
            Log::info('[UpdateProfile] User saved successfully');
            DB::commit();

            // Post-success cleanup: remove old avatar if replaced
            if ($avatarPath && $oldAvatarPath) {
                if (Storage::disk('public')->exists($oldAvatarPath)) {
                    Storage::disk('public')->delete($oldAvatarPath);
                }
            }
        } catch (\Throwable $e) {
            Log::error('[UpdateProfile] Error during update: ' . $e->getMessage());
            Log::error('[UpdateProfile] Stack trace: ' . $e->getTraceAsString());
            if (isset($avatarPath) && $avatarPath) {
                Storage::disk('public')->delete($avatarPath);
            }
            DB::rollBack();
            throw $e;
        }

        // If email was changed, send verification code for the NEW email
        if ($emailChanged) {
            try {
                $token = hash('sha256', $user->getKey() . $user->email_pending);
                SendVerificationCodeEmailJob::dispatch($user->email_pending, $token);
                Log::info('[UpdateProfile] Queued verification code email to: ' . $user->email_pending);
            } catch (\Exception $e) {
                Log::error('[UpdateProfile] Failed to queue verification email: ' . $e->getMessage());
            }
        }

        return response()->json([
            'message' => $emailChanged
                ? 'Profile updated. Please verify your new email address.'
                : 'Profile updated successfully',
            'data' => $user->only(['id', 'name', 'email', 'avatar_url', 'wallet_balance']),
            'email_changed' => $emailChanged,
        ], 200);
    }
}
