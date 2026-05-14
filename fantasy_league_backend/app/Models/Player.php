<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Player extends Model
{
    protected $fillable = ['name', 'role', 'player_role_id', 'image_url', 'game_match_id', 'is_playing', 'nationality', 'country_id'];

    protected $casts = [
        'is_playing' => 'boolean',
    ];

    public function gameMatch()
    {
        return $this->belongsTo(GameMatch::class);
    }

    public function gameTeam()
    {
        return $this->belongsTo(Team::class, 'game_team_id');
    }

    public function playerRole()
    {
        return $this->belongsTo(PlayerRole::class);
    }

    public function country()
    {
        return $this->belongsTo(Country::class);
    }

    public function selections()
    {
        return $this->hasMany(PlayerSelection::class);
    }

    /**
     * Teams this player is assigned to (many-to-many via player_selections)
     */
    public function teams()
    {
        return $this->belongsToMany(Team::class, 'player_selections', 'player_id', 'team_id')
                    ->using(PlayerSelection::class)
                    ->withPivot(['captain', 'vice_captain'])
                    ->withTimestamps();
    }

    /**
     * Get all match points for this player
     */
    public function matchPoints()
    {
        return $this->hasMany(MatchPlayerPoints::class);
    }

    /**
     * Calculate total points for a specific tournament (on-the-fly)
     *
     * @param int|null $tournamentId Tournament ID (null for all tournaments)
     * @return int Sum of points across all matches
     */
    public function getTotalPoints($tournamentId = null)
    {
        $query = $this->matchPoints();

        if ($tournamentId) {
            $query->where('tournament_id', $tournamentId);
        }

        return (int) $query->sum('points');
    }

    /**
     * Calculate points for a specific match
     *
     * @param int $matchId Game Match ID
     * @return int Points for this player in that match
     */
    public function getMatchPoints($matchId)
    {
        return (int) $this->matchPoints()
            ->where('game_match_id', $matchId)
            ->first()?->points ?? 0;
    }

    /**
     * Get player's tournament participation (which tournaments they played in)
     *
     * @return \Illuminate\Database\Eloquent\Collection
     */
    public function getTournaments()
    {
        return Tournament::whereHas('matches', function ($query) {
            $query->whereHas('playerPoints', function ($q) {
                $q->where('player_id', $this->id);
            });
        })->get();
    }
}
