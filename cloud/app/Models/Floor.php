<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Floor extends Model
{
    use HasFactory, HasUuids;

    protected $connection = 'tenant';

    protected $fillable = ['restaurant_id', 'menu_card_id', 'name', 'sort_order'];
    
    protected static function booted()
    {
        static::deleting(function ($floor) {
            $floor->tables->each->delete();
        });
    }

    public function tables()
    {
        return $this->hasMany(RestaurantTable::class, 'floor_id');
    }

    public function menuCard()
    {
        return $this->belongsTo(MenuCard::class, 'menu_card_id');
    }
}
