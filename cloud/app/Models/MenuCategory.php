<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class MenuCategory extends Model
{
    use HasFactory, HasUuids;

    protected $connection = 'tenant';

    protected $fillable = ['menu_card_id', 'kds_station_id', 'name', 'sort_order', 'is_active'];
    
    protected static function booted()
    {
        static::deleting(function ($menuCategory) {
            $menuCategory->items->each->delete();
        });
    }

    public function menuCard()
    {
        return $this->belongsTo(MenuCard::class);
    }

    public function kdsStation()
    {
        return $this->belongsTo(KDSStation::class, 'kds_station_id');
    }

    public function items()
    {
        return $this->hasMany(MenuItem::class)->orderBy('sort_order');
    }
}
