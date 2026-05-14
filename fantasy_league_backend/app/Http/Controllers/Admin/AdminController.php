<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\DB;
use Inertia\Inertia;

class AdminController extends Controller
{
    public function index(Request $request)
    {
        $filters = $request->only(['q', 'per_page']);
        $perPage = (int) ($request->query('per_page', 15));

        $admins = User::where('is_admin', true)
            ->when($request->query('q'), function ($query, $q) {
                $query->where(function ($q2) use ($q) {
                    $q2->where('name', 'like', "%{$q}%")
                        ->orWhere('email', 'like', "%{$q}%");
                });
            })->latest()->paginate($perPage)->withQueryString();

        return Inertia::render('Admin/Admins/Index', compact('admins', 'filters'));
    }

    public function create()
    {
        return Inertia::render('Admin/Admins/Create');
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
            $admin = User::create([
                'name' => $validated['name'],
                'email' => $validated['email'],
                'password' => Hash::make($validated['password']),
                'is_admin' => true,
            ]);

            // Upload avatar if provided (same pattern as app and user controller)
            if ($request->hasFile('avatar')) {
                $avatarFile = $request->file('avatar');
                $avatarPath = $avatarFile->storeAs(
                    'avatars/' . $admin->id,
                    $avatarFile->hashName(),
                    'public'
                );
                $admin->update(['avatar_url' => Storage::url($avatarPath)]);
            }

            DB::commit();
        } catch (\Throwable $e) {
            DB::rollBack();
            throw $e;
        }

        return to_route('admin.admins.index')->with('success', 'Admin created successfully');
    }

    public function edit(User $admin)
    {
        return Inertia::render('Admin/Admins/Edit', compact('admin'));
    }

    public function update(Request $request, User $admin)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|email|unique:users,email,'.$admin->id,
            'password' => 'nullable|string|min:6|confirmed',
            'avatar' => 'nullable|image|mimes:jpg,jpeg,png,gif|max:4096',
            'remove_avatar' => 'nullable|boolean',
        ]);

        // Prepare data for update
        $data = [
            'name' => $validated['name'],
            'email' => $validated['email'],
        ];

        if ($request->filled('password')) {
            $data['password'] = Hash::make($request->password);
        }

        // Cache old avatar path before any changes
        $oldAvatarPath = null;
        if ($admin->avatar_url) {
            $oldAvatarPath = str_replace('/storage/', '', $admin->avatar_url);
        }

        $newAvatarPath = null;

        DB::beginTransaction();
        try {
            // Handle avatar upload (same pattern as app authorization controller for consistency)
            if ($request->hasFile('avatar')) {
                $avatarFile = $request->file('avatar');
                $newAvatarPath = $avatarFile->storeAs(
                    'avatars/' . $admin->id,
                    $avatarFile->hashName(),
                    'public'
                );
                $data['avatar_url'] = Storage::url($newAvatarPath);
            }

            // Handle avatar removal
            if ($request->boolean('remove_avatar')) {
                $data['avatar_url'] = null;
            }

            // Update the admin
            $admin->update($data);

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
                'message' => 'Admin updated successfully!',
                'admin' => $admin,
            ]);
        }

        return redirect()->route('admin.admins.edit', $admin->id)
            ->with('success', 'Admin updated successfully!');
    }

    public function destroy(User $admin)
    {
        // Prevent deleting the last admin
        $adminCount = User::where('is_admin', true)->count();
        if ($adminCount <= 1) {
            return back()->with('error', 'Cannot delete the last admin user!');
        }

        try {
            // Clean up avatar if exists
            if ($admin->avatar_url) {
                $path = str_replace('/storage/', '', $admin->avatar_url);
                if (Storage::disk('public')->exists($path)) {
                    Storage::disk('public')->delete($path);
                }
            }

            $admin->delete();
            return redirect()->route('admin.admins.index')->with('success', 'Admin deleted successfully!');
        } catch (\Exception $e) {
            return back()->with('error', 'Failed to delete admin: ' . $e->getMessage());
        }
    }
}
