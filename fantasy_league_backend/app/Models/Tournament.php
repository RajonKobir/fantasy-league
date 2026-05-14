<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Tournament extends Model
{
    protected $fillable = ['name', 'logo_url', 'description', 'start_at', 'end_at', 'entry_fee', 'required_players', 'captain_multiplier', 'vice_captain_multiplier', 'refund_percentage', 'status'];

    protected $casts = [
        'entry_fee' => 'decimal:2',
        'required_players' => 'integer',
        'captain_multiplier' => 'decimal:2',
        'vice_captain_multiplier' => 'decimal:2',
        'refund_percentage' => 'decimal:2',
        'start_at' => 'datetime',
        'end_at' => 'datetime',
    ];

    public function teams()
    {
        return $this->belongsToMany(Team::class, 'tournament_team')->withTimestamps();
    }

    public function fantasyTeams()
    {
        return $this->hasMany(FantasyTeam::class);
    }
}
