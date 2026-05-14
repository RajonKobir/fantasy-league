<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class AdminWalletLog extends Model
{
    use HasFactory;

    protected $table = 'admin_wallet_logs';

    protected $fillable = [
        'admin_id',
        'user_id',
        'action',
        'amount',
        'previous_balance',
        'new_balance',
        'remark',
    ];

    public function admin()
    {
        return $this->belongsTo(User::class, 'admin_id');
    }

    public function user()
    {
        return $this->belongsTo(User::class, 'user_id');
    }
}
