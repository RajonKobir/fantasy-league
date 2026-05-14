<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Relations\Pivot;

class PlayerSelection extends Pivot
{
    // Table name is plural in migrations: 'player_selections'
    protected $table = 'player_selections';

    protected $fillable = ['team_id', 'player_id', 'captain', 'vice_captain'];

    public function team()
    {
        return $this->belongsTo(Team::class);
    }

    public function player()
    {
        return $this->belongsTo(Player::class);
    }
}
