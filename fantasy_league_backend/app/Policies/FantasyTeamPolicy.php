<?php

namespace App\Policies;

use App\Models\FantasyTeam;
use App\Models\User;

class FantasyTeamPolicy
{
    /**
     * Only the owner of a fantasy team can view it
     */
    public function view(User $user, FantasyTeam $fantasyTeam): bool
    {
        return $user->id === $fantasyTeam->user_id || $user->is_admin;
    }

    /**
     * Only the owner can update their fantasy team
     */
    public function update(User $user, FantasyTeam $fantasyTeam): bool
    {
        return $user->id === $fantasyTeam->user_id || $user->is_admin;
    }

    /**
     * Only the owner can delete their fantasy team
     */
    public function delete(User $user, FantasyTeam $fantasyTeam): bool
    {
        return $user->id === $fantasyTeam->user_id || $user->is_admin;
    }
}
