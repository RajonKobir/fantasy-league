<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Transaction extends Model
{
    use HasFactory;

    protected $fillable = ['user_id', 'transaction_id', 'type', 'remark', 'amount', 'team_name', 'status_request', 'status_process', 'status_credit', 'time', 'description', 'payment_method', 'reference_type', 'reference_id'];

    protected $casts = [
        'time' => 'datetime',
        'amount' => 'decimal:2',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
