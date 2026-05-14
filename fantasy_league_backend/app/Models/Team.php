<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Team extends Model
{
    // Teams represent game teams (India, Pakistan, etc.) with many players
    protected $fillable = ['name', 'logo_url', 'user_id', 'tournament_id', 'points'];

    public function user()
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    public function players()
    {
        return $this->hasMany(Player::class, 'game_team_id');
    }

    public function matchesAsTeamA()
    {
        return $this->hasMany(GameMatch::class, 'team_a_id');
    }

    public function matchesAsTeamB()
    {
        return $this->hasMany(GameMatch::class, 'team_b_id');
    }

    public function selections()
    {
        return $this->hasMany(PlayerSelection::class);
    }

    // legacy alias used by controllers
    public function playerSelections()
    {
        return $this->selections();
    }

    /**
     * Players assigned to this team via the `player_selections` junction table.
     */
    public function assignedPlayers()
    {
        return $this->belongsToMany(Player::class, 'player_selections', 'team_id', 'player_id')
                    ->using(PlayerSelection::class)
                    ->withPivot(['captain', 'vice_captain'])
                    ->withTimestamps();
    }

    public function tournaments()
    {
        return $this->belongsToMany(Tournament::class, 'tournament_team')->withTimestamps();
    }
}
