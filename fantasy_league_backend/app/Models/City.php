<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class City extends Model
{
    protected $fillable = ['country_id', 'name', 'lat', 'lng'];

    public function country()
    {
        return $this->belongsTo(Country::class);
    }

    public function matches()
    {
        return $this->hasMany(GameMatch::class, 'venue_id');
    }
}
