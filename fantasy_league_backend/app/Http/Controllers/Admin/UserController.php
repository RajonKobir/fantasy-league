<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\DB;
use Inertia\Inertia;

class UserController extends Controller
{
    public function index(Request $request)
    {
        $filters = $request->only(['q', 'per_page']);
        $perPage = (int) ($request->query('per_page', 15));

        $users = User::where('is_admin', false)
            ->when($request->query('q'), function ($query, $q) {
                $query->where(function ($q2) use ($q) {
                    $q2->where('name', 'like', "%{$q}%")
                        ->orWhere('email', 'like', "%{$q}%");
                });
            })->latest()->paginate($perPage)->withQueryString();

        return Inertia::render('Admin/Users/Index', compact('users', 'filters'));
    }

    public function create()
    {
        return Inertia::render('Admin/Users/Create');
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|email|unique:users,email',
            'password' => 'required|string|min:6|confirmed',
            'avatar' => 'nullable|image|mimes:jpg,jpeg,png,gif|max:4096',
        ]);

        DB::beginTransaction();
        try {
            $user = User::create([
                'name' => $validated['name'],
                'email' => $validated['email'],
                'password' => Hash::make($validated['password']),
                'is_admin' => false,
            ]);

            // Upload avatar if provided
            if ($request->hasFile('avatar')) {
                $avatarFile = $request->file('avatar');
                $avatarPath = $avatarFile->storeAs(
                    'avatars/' . $user->id,
                    $avatarFile->hashName(),
                    'public'
                );
                $user->update(['avatar_url' => Storage::url($avatarPath)]);
            }

            DB::commit();
        } catch (\Throwable $e) {
            DB::rollBack();
            throw $e;
        }

        return to_route('admin.users.index')->with('success', 'User created successfully');
    }

    public function edit(User $user)
    {
        return Inertia::render('Admin/Users/Edit', compact('user'));
    }

    public function update(Request $request, User $user)
    {
        $rules = [
            'avatar' => 'nullable|image|mimes:jpg,jpeg,png,gif|max:4096',
            'remove_avatar' => 'nullable|boolean',
        ];

        // Name is optional, but if provided must not be empty
        if ($request->filled('name')) {
            $rules['name'] = 'required|string|max:255';
        }

        // Email is optional, but if provided must be valid and unique (except current user)
        if ($request->filled('email')) {
            $rules['email'] = 'required|email|unique:users,email,'.$user->id;
        }

        // Password is optional, but if provided must be at least 6 chars and confirmed
        if ($request->filled('password')) {
            $rules['password'] = 'required|string|min:6|confirmed';
            $rules['password_confirmation'] = 'required|string|min:6';
        }

        $validated = $request->validate($rules);

        // Prepare data for update (only include fields that were provided)
        $data = [];
        if (array_key_exists('name', $validated)) {
            $data['name'] = $validated['name'];
        }
        if (array_key_exists('email', $validated)) {
            $data['email'] = $validated['email'];
        }

        if (array_key_exists('password', $validated)) {
            $data['password'] = Hash::make($validated['password']);
        }

        // Cache old avatar path for cleanup after successful transaction
        $oldAvatarPath = null;
        if ($user->avatar_url) {
            $oldAvatarPath = str_replace('/storage/', '', $user->avatar_url);
        }

        $newAvatarPath = null;

        DB::beginTransaction();
        try {
            // Handle avatar upload (same as app authorization controller for consistency)
            if ($request->hasFile('avatar')) {
                $avatarFile = $request->file('avatar');
                $newAvatarPath = $avatarFile->storeAs(
                    'avatars/' . $user->id,
                    $avatarFile->hashName(),
                    'public'
                );
                $data['avatar_url'] = Storage::url($newAvatarPath);
            }

            // Handle avatar removal
            if ($request->boolean('remove_avatar')) {
                $data['avatar_url'] = null;
            }

            // Update the user
            $user->update($data);

            DB::commit();

            // Post-commit cleanup: delete old avatar after successful transaction
            // Delete if: (1) new avatar uploaded, OR (2) avatar was removed
            $shouldDeleteOld = ($newAvatarPath && $oldAvatarPath) ||
                               ($request->boolean('remove_avatar') && $oldAvatarPath);

            if ($shouldDeleteOld && $oldAvatarPath && Storage::disk('public')->exists($oldAvatarPath)) {
                Storage::disk('public')->delete($oldAvatarPath);
            }

        } catch (\Throwable $e) {
            // Rollback transaction
            if ($newAvatarPath) {
                Storage::disk('public')->delete($newAvatarPath);
            }
            DB::rollBack();
            throw $e;
        }

        // Return JSON for AJAX requests, redirect for form submissions
        if ($request->wantsJson()) {
            return response()->json([
                'success' => true,
                'message' => 'User updated successfully!',
                'user' => $user,
            ]);
        }

        return redirect()->route('admin.users.index')
            ->with('success', 'User updated successfully!');
    }

    public function destroy(User $user)
    {
        if ($user->avatar_url) {
            $oldPath = str_replace('/storage/', '', $user->avatar_url);
            if (Storage::disk('public')->exists($oldPath)) {
                Storage::disk('public')->delete($oldPath);
            }
        }

        $user->delete();

        return to_route('admin.users.index')->with('success', 'User deleted');
    }
}
