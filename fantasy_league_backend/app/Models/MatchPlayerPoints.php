<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class MatchPlayerPoints extends Model
{
    protected $table = 'match_player_points';

    protected $fillable = [
        'game_match_id',
        'tournament_id',
        'player_id',
        'points',
        'note',
    ];

    protected $casts = [
        'points' => 'integer',
    ];

    /**
     * Get the Game Match that owns this point record
     */
    public function gameMatch(): BelongsTo
    {
        return $this->belongsTo(GameMatch::class);
    }

    /**
     * Get the tournament that owns this point record
     */
    public function tournament(): BelongsTo
    {
        return $this->belongsTo(Tournament::class);
    }

    /**
     * Get the player that owns this point record
     */
    public function player(): BelongsTo
    {
        return $this->belongsTo(Player::class);
    }
}
