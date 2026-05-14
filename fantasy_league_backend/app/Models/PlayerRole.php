<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class PlayerRole extends Model
{
    protected $fillable = ['name', 'slug', 'description'];

    public function players()
    {
        return $this->hasMany(Player::class);
    }
}
