<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Team;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

/**
 * TeamController
 *
 * NOTE: This controller is for GAME TEAMS (India, Pakistan, etc.)
 * NOT user-created fantasy teams. Fantasy teams are handled by FantasyTeamController.
 *
 * Game teams are admin-managed and are used in GameMatches.
 */
class TeamController extends Controller
{
    // GET /api/teams (list all game teams with optional search + pagination)
    public function index(Request $request): JsonResponse
    {
        $perPage = (int) $request->query('per_page', 15);

        $query = Team::query();
        if ($request->query('q')) {
            $q = $request->query('q');
            $query->where('name', 'like', "%{$q}%")
                  ->orWhereHas('user', fn($q2) => $q2->where('name', 'like', "%{$q}%"));
        }

        $teams = $query->orderBy('name')->paginate($perPage);

        $teams->getCollection()->transform(function ($team) {
            $team->logo_url = $team->logo_url ?? config('app.placeholder_image');
            return $team;
        });

        return response()->json(['success' => true, 'data' => $teams]);
    }

    // GET /api/me/teams — teams owned by the authenticated user
    public function myTeams(Request $request): JsonResponse
    {
        $teams = Team::where('user_id', $request->user()->id)->get();
        return response()->json(['success' => true, 'data' => $teams]);
    }

    // GET /api/game-teams/{team} (show one game team with all players)
    public function show(Team $team): JsonResponse
    {
        $team->load(['players:id,name,role,image_url,game_team_id']);
        $team->logo_url = $team->logo_url ?? config('app.placeholder_image');

        // If there are player selections (legacy teams created via /api/teams), include them in the response
        $selections = $team->selections()->get(['player_id', 'captain', 'vice_captain'])->map(function ($s) {
            return [
                'player_id' => $s->player_id,
                'captain' => (int) $s->captain,
                'vice_captain' => (int) $s->vice_captain,
            ];
        })->toArray();

        $arr = $team->toArray();
        $arr['selections'] = $selections;

        return response()->json([
            'success' => true,
            'data' => $arr,
        ]);
    }

    // Admin: update a game team (logo upload supported)
    public function update(Request $request, Team $team): JsonResponse
    {
        $request->validate([
            'name' => 'sometimes|required|string|max:255',
            'user_id' => 'nullable|exists:users,id',
            'logo' => 'nullable|image|max:4096',
            'remove_logo' => 'nullable|boolean',
        ]);

        $oldPath = $team->logo_url ? str_replace('/storage/', '', $team->logo_url) : null;
        $tmpPath = null;
        $newPath = null;

        try {
            $newLogoUploaded = false;
            if ($request->boolean('remove_logo')) {
                $team->logo_url = null;
            }

            if ($request->hasFile('logo')) {
                $tmpPath = $request->file('logo')->store('teams/tmp', 'public');
                $newPath = 'teams/'.$team->id.'/'.basename($tmpPath);
                Storage::disk('public')->move($tmpPath, $newPath);
                $team->logo_url = Storage::url($newPath);
                $newLogoUploaded = true;
            }

            if ($request->filled('name')) {
                $team->name = $request->input('name');
            }
            if ($request->filled('user_id')) {
                $team->user_id = $request->input('user_id');
            }

            $team->save();

            if ($newLogoUploaded && $oldPath && Storage::disk('public')->exists($oldPath)) {
                Storage::disk('public')->delete($oldPath);
            }

            if ($request->boolean('remove_logo') && $oldPath && Storage::disk('public')->exists($oldPath)) {
                Storage::disk('public')->delete($oldPath);
            }

            return response()->json(['success' => true, 'data' => $team->fresh()]);
        } catch (\Throwable $e) {
            // cleanup
            if ($tmpPath && Storage::disk('public')->exists($tmpPath)) {
                Storage::disk('public')->delete($tmpPath);
            }
            if ($newPath && Storage::disk('public')->exists($newPath)) {
                Storage::disk('public')->delete($newPath);
            }
            throw $e;
        }
    }

    // Admin: delete a team
    public function destroy(Team $team): JsonResponse
    {
        if ($team->logo_url) {
            $oldPath = str_replace('/storage/', '', $team->logo_url);
            if (Storage::disk('public')->exists($oldPath)) {
                Storage::disk('public')->delete($oldPath);
            }
        }

        $team->delete();

        return response()->json(['success' => true]);
    }
}
