<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Winner extends Model
{
    protected $table = 'winners';

    protected $fillable = [
        'tournament_id',
        'tournament_name',
        'fantasy_teams_ids',
        'fantasy_teams_names',
        'user_ids',
        'user_names',
        'total_points',
        'status',
    ];

    protected $casts = [
        'fantasy_teams_ids' => 'array',
        'fantasy_teams_names' => 'array',
        'user_ids' => 'array',
        'user_names' => 'array',
        'total_points' => 'array',
    ];

    public function tournament()
    {
        return $this->belongsTo(Tournament::class);
    }
}
