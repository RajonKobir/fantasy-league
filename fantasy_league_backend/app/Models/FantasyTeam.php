<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class FantasyTeam extends Model
{
    use HasFactory;

    protected $fillable = ['tournament_id', 'user_id', 'player_ids', 'name', 'captain_id', 'vice_captain_id', 'total_points', 'status'];

    protected $casts = [
        'player_ids' => 'array',
        'total_points' => 'integer',
    ];

    public function tournament()
    {
        return $this->belongsTo(Tournament::class);
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function captain()
    {
        return $this->belongsTo(Player::class, 'captain_id');
    }

    public function viceCaptain()
    {
        return $this->belongsTo(Player::class, 'vice_captain_id');
    }

    public function cancelRequest()
    {
        return $this->hasOne(CancelRequest::class);
    }

    public function players()
    {
        return Player::whereIn('id', $this->player_ids ?? []);
    }

    /**
     * Calculate total points dynamically from match_player_points
     * (alternative to cached total_points for real-time calculation)
     */
    public function calculateTotalPoints()
    {
        return (int) \App\Models\MatchPlayerPoints::whereIn('player_id', $this->player_ids ?? [])
            ->where('tournament_id', $this->tournament_id)
            ->sum('points');
    }

    /**
     * Get team's rank in tournament based on total_points
     */
    public function getRank()
    {
        return FantasyTeam::where('tournament_id', $this->tournament_id)
            ->where('total_points', '>', $this->total_points)
            ->count() + 1;
    }
}
