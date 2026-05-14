<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\DB;
use Inertia\Inertia;

class AdminProfileController extends Controller
{
    /**
     * Show the admin profile page
     */
    public function show(Request $request)
    {
        return Inertia::render('Admin/Profile', [
            'user' => $request->user(),
        ]);
    }

    /**
     * Update profile information (name, email, avatar)
     */
    public function update(Request $request)
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'email', 'unique:users,email,' . $request->user()->id],
            'avatar_url' => ['nullable', 'image', 'max:2048'], // 2MB max
            'remove_avatar' => ['nullable', 'boolean'],
        ]);

        $user = $request->user();

        // Cache old avatar path for post-commit cleanup
        $oldPath = null;
        if ($user->avatar_url) {
            $oldPath = str_replace('/storage/', '', $user->avatar_url);
        }

        $newPath = null;

        DB::beginTransaction();
        try {
            // Handle avatar upload (same pattern as app authorization controller for consistency)
            if ($request->hasFile('avatar_url')) {
                $avatarFile = $request->file('avatar_url');
                $newPath = $avatarFile->storeAs(
                    'avatars/' . $user->id,
                    $avatarFile->hashName(),
                    'public'
                );
                $validated['avatar_url'] = Storage::url($newPath);
            }

            // Handle explicit avatar removal
            if ($request->boolean('remove_avatar')) {
                $validated['avatar_url'] = null;
            }

            $user->update($validated);

            DB::commit();

            // Post-commit cleanup: delete old file after successful transaction
            // Delete if: (1) new avatar uploaded, OR (2) avatar was removed
            $shouldDeleteOld = ($newPath && $oldPath) ||
                               ($request->boolean('remove_avatar') && $oldPath);

            if ($shouldDeleteOld && $oldPath && Storage::disk('public')->exists($oldPath)) {
                Storage::disk('public')->delete($oldPath);
            }
        } catch (\Throwable $e) {
            if (isset($newPath)) {
                Storage::disk('public')->delete($newPath);
            }
            DB::rollBack();
            throw $e;
        }

        // Redirect to profile page to force a fresh GET request which refreshes shared auth props
        return redirect()->route('admin.profile.show')->with('success', 'Profile updated successfully.');
    }

    /**
     * Update password
     */
    public function updatePassword(Request $request)
    {
        $validated = $request->validate([
            'password' => [
                'required',
                'string',
                'min:8',
                'regex:/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]/',
                'confirmed',
            ],
        ]);

        $request->user()->update([
            'password' => Hash::make($validated['password']),
        ]);

        // Redirect to profile page to refresh shared auth props and show flash
        return redirect()->route('admin.profile.show')->with('success', 'Password updated successfully.');
    }
}
