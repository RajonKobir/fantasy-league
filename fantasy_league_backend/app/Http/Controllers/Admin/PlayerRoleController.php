<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\PlayerRole;
use Illuminate\Http\Request;
use Inertia\Inertia;
use Illuminate\Support\Str;

class PlayerRoleController extends Controller
{
    /**
     * Display list of player roles
     */
    public function index()
    {
        $roles = PlayerRole::withCount('players')->latest()->paginate(25);

        return Inertia::render('Admin/PlayerRoles/Index', compact('roles'));
    }

    /**
     * Show create role form
     */
    public function create()
    {
        return Inertia::render('Admin/PlayerRoles/Create');
    }

    /**
     * Store a new player role
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|unique:player_roles,name',
            'description' => 'nullable|string|max:1000',
        ]);

        // Auto-generate slug from name
        $validated['slug'] = Str::slug($validated['name']);

        PlayerRole::create($validated);

        return redirect()->route('admin.player-roles.index')->with('success', 'Player role created successfully');
    }

    /**
     * Show edit role form
     */
    public function edit(PlayerRole $playerRole)
    {
        return Inertia::render('Admin/PlayerRoles/Edit', compact('playerRole'));
    }

    /**
     * Update a player role
     */
    public function update(Request $request, PlayerRole $playerRole)
    {
        $validated = $request->validate([
            'name' => 'required|string|unique:player_roles,name,' . $playerRole->id,
            'description' => 'nullable|string|max:1000',
        ]);

        // Update slug if name changed
        $validated['slug'] = Str::slug($validated['name']);

        $playerRole->update($validated);

        return redirect()->route('admin.player-roles.index')->with('success', 'Player role updated successfully');
    }

    /**
     * Delete a player role
     */
    public function destroy(PlayerRole $playerRole)
    {
        // Check if role has players assigned
        if ($playerRole->players()->count() > 0) {
            return back()->withErrors(['error' => 'Cannot delete role that has players assigned']);
        }

        $playerRole->delete();

        return redirect()->route('admin.player-roles.index')->with('success', 'Player role deleted successfully');
    }
}
