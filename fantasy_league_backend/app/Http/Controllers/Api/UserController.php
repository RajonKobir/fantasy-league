<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\DB;

class UserController extends Controller
{
    // Admin: list users (paginated)
    public function index(Request $request): JsonResponse
    {
        $perPage = max(10, (int) $request->query('per_page', 25));
        $users = User::select(['id', 'name', 'email', 'is_admin', 'avatar_url', 'wallet_balance'])
            ->when($request->query('q'), function ($query, $q) {
                $query->where(function ($q2) use ($q) {
                    $q2->where('name', 'like', "%{$q}%")
                        ->orWhere('email', 'like', "%{$q}%");
                });
            })->paginate($perPage);
        // add placeholder avatar for any users without avatars
        $users->getCollection()->transform(function ($u) {
            $arr = $u->toArray();
            $arr['avatar_url'] = $arr['avatar_url'] ?? config('app.placeholder_image');

            return $arr;
        });

        return response()->json(['success' => true, 'data' => $users]);
    }

    // Admin: update user
    public function update(Request $request, User $user): JsonResponse
    {
        $request->validate([
            'name' => 'sometimes|required|string|max:255',
            'email' => 'sometimes|required|email|unique:users,email,'.$user->id,
            'password' => 'nullable|string|min:6|confirmed',
            'is_admin' => 'nullable|boolean',
            'avatar' => 'nullable|image|max:4096',
        ]);

        $data = $request->only(['name', 'email', 'is_admin']);

        if ($request->filled('password')) {
            $data['password'] = Hash::make($request->password);
        }

        $oldPath = null;
        if ($user->avatar_url) {
            $oldPath = str_replace('/storage/', '', $user->avatar_url);
        }

        DB::beginTransaction();
        try {
            if ($request->hasFile('avatar')) {
                $avatarFile = $request->file('avatar');
                $path = $avatarFile->storeAs(
                    'avatars/' . $user->id,
                    $avatarFile->hashName(),
                    'public'
                );
                $data['avatar_url'] = Storage::url($path);
            }

            if ($request->filled('password')) {
                $data['password'] = Hash::make($request->password);
            }

            $user->update($data);

            DB::commit();

            // cleanup old file after success
            if (isset($path) && $oldPath) {
                if (Storage::disk('public')->exists($oldPath)) {
                    Storage::disk('public')->delete($oldPath);
                }
            }
        } catch (\Throwable $e) {
            if (isset($path)) {
                Storage::disk('public')->delete($path);
            }
            DB::rollBack();
            throw $e;
        }

        return response()->json(['success' => true, 'data' => $user]);
    }

    // Admin: delete user
    public function destroy(User $user): JsonResponse
    {
        if ($user->avatar_url) {
            $oldPath = str_replace('/storage/', '', $user->avatar_url);
            if (Storage::disk('public')->exists($oldPath)) {
                Storage::disk('public')->delete($oldPath);
            }
        }

        $user->delete();

        return response()->json(['success' => true, 'message' => 'User deleted']);
    }
}
