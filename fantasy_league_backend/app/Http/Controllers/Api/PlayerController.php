<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Player;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\DB;

class PlayerController extends Controller
{
    // GET /api/players
    public function index(Request $request): JsonResponse
    {
        $perPage = max(10, (int) $request->query('per_page', 25));

        $players = Player::select(['id', 'name', 'role', 'nationality', 'image_url'])
            ->when($request->query('q'), function ($query, $q) {
                $query->where(function ($q2) use ($q) {
                    $q2->where('name', 'like', "%{$q}%")
                        ->orWhere('nationality', 'like', "%{$q}%");
                });
            })->paginate($perPage);

        // ensure image_url fallback for the page's collection
        $players->getCollection()->transform(function ($p) {
            $arr = $p->toArray();
            $arr['image_url'] = $arr['image_url'] ?? config('app.placeholder_image');

            return $arr;
        });

        return response()->json([
            'success' => true,
            'data' => $players,
        ]);
    }

    // Admin-only: POST /api/players
    public function store(Request $request): JsonResponse
    {
        // Accept legacy `team` param and map to `nationality`
        if ($request->has('team') && ! $request->has('nationality')) {
            $request->merge(['nationality' => $request->input('team')]);
        }

        $request->validate([
            'name' => 'required|string|max:255',
            'role' => 'nullable|string',
            'nationality' => 'nullable|string|max:100|required_without:country_id',
            'country_id' => 'nullable|integer|exists:countries,id',
            'image' => 'nullable|image|max:2048',
            'game_match_id' => 'nullable|exists:game_matches,id',
            'is_playing' => 'nullable|boolean',
        ]);

        $data = $request->only(['name', 'role', 'nationality', 'country_id', 'game_match_id', 'is_playing']);

        // Normalize role to allow case-insensitive input
        if (isset($data['role'])) {
            $data['role'] = strtolower($data['role']);
            $allowedRoles = ['batsman','bowler','all-rounder','wicket-keeper'];
            if (! in_array($data['role'], $allowedRoles)) {
                return response()->json(['success' => false, 'message' => 'Invalid role'], 422);
            }
        }

        DB::beginTransaction();
        try {
            if ($request->hasFile('image')) {
                $path = $request->file('image')->store('players', 'public');
                $data['image_url'] = Storage::url($path);
            }

            // If country_id provided but nationality not set, resolve to country's name
            if (empty($data['nationality']) && ! empty($data['country_id'])) {
                $country = \App\Models\Country::find($data['country_id']);
                if ($country) {
                    $data['nationality'] = $country->name;
                }
            }

            $player = Player::create($data);

            DB::commit();
        } catch (\Throwable $e) {
            if (isset($path)) {
                Storage::disk('public')->delete($path);
            }
            DB::rollBack();
            throw $e;
        }

        return response()->json(['success' => true, 'data' => $player], 201);
    }

    // Admin-only: PUT /api/players/{player}
    public function update(Request $request, Player $player): JsonResponse
    {
        // Accept legacy `team` param and map to `nationality`
        if ($request->has('team') && ! $request->has('nationality')) {
            $request->merge(['nationality' => $request->input('team')]);
        }

        $request->validate([
            'name' => 'sometimes|required|string|max:255',
            'role' => 'nullable|string',
            'nationality' => 'sometimes|nullable|string|max:100',
            'country_id' => 'nullable|integer|exists:countries,id',
            'image' => 'nullable|image|max:2048',
            'game_match_id' => 'nullable|exists:game_matches,id',
            'is_playing' => 'nullable|boolean',
        ]);

        $data = $request->only(['name', 'role', 'nationality', 'country_id', 'game_match_id', 'is_playing']);

        if (isset($data['role'])) {
            $data['role'] = strtolower($data['role']);
            $allowedRoles = ['batsman','bowler','all-rounder','wicket-keeper'];
            if (! in_array($data['role'], $allowedRoles)) {
                return response()->json(['success' => false, 'message' => 'Invalid role'], 422);
            }
        }

        $oldPath = null;
        if ($player->image_url) {
            $oldPath = str_replace('/storage/', '', $player->image_url);
        }

        DB::beginTransaction();
        try {
            if ($request->hasFile('image')) {
                $path = $request->file('image')->store('players', 'public');
                $data['image_url'] = Storage::url($path);
            }

            // If country_id provided but nationality not set, resolve to country's name
            if (empty($data['nationality']) && ! empty($data['country_id'])) {
                $country = \App\Models\Country::find($data['country_id']);
                if ($country) {
                    $data['nationality'] = $country->name;
                }
            }

            $player->update($data);

            DB::commit();

            // cleanup old file after successful update
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

        return response()->json(['success' => true, 'data' => $player]);
    }

    // Admin-only: DELETE /api/players/{player}
    public function destroy(Player $player): JsonResponse
    {
        if ($player->image_url) {
            $oldPath = str_replace('/storage/', '', $player->image_url);
            if (Storage::disk('public')->exists($oldPath)) {
                Storage::disk('public')->delete($oldPath);
            }
        }
        $player->delete();

        return response()->json(['success' => true, 'message' => 'Player deleted']);
    }
}
