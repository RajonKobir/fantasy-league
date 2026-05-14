<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class CancelRequest extends Model
{
    protected $fillable = [
        'fantasy_team_id',
        'user_id',
        'tournament_id',
        'status',
        'refund_amount',
        'refund_percentage_at_request',
        'admin_notes',
        'approved_by',
        'approved_at',
    ];

    protected $casts = [
        'refund_amount' => 'decimal:2',
        'refund_percentage_at_request' => 'decimal:2',
        'approved_at' => 'datetime',
    ];

    public function fantasyTeam()
    {
        return $this->belongsTo(FantasyTeam::class);
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function tournament()
    {
        return $this->belongsTo(Tournament::class);
    }

    public function approvedBy()
    {
        return $this->belongsTo(User::class, 'approved_by');
    }
}
