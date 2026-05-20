<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class MenuCard extends Model
{
    use HasFactory, HasUuids;

    protected $connection = 'tenant';

    protected $fillable = ['restaurant_id', 'name', 'is_active'];
    
    protected static function booted()
    {
        static::deleting(function ($menuCard) {
            $menuCard->categories->each->delete();
        });
    }

    public function categories()
    {
        return $this->hasMany(MenuCategory::class)->orderBy('sort_order');
    }
}
