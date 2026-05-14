<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class GameMatch extends Model
{
    protected $fillable = ['team_a_id', 'team_b_id', 'tournament_id', 'start_time', 'status', 'venue_id'];

    public function teamA()
    {
        return $this->belongsTo(Team::class, 'team_a_id');
    }

    public function teamB()
    {
        return $this->belongsTo(Team::class, 'team_b_id');
    }

    public function tournament()
    {
        return $this->belongsTo(Tournament::class);
    }

    public function venue()
    {
        return $this->belongsTo(City::class, 'venue_id');
    }

    public function players()
    {
        return $this->hasMany(Player::class);
    }

    /**
     * Get all player points for this match
     */
    public function playerPoints()
    {
        return $this->hasMany(MatchPlayerPoints::class);
    }
}
