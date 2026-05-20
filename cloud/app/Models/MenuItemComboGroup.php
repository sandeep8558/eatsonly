<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class MenuItemComboGroup extends Model
{
    use HasFactory, HasUuids;

    protected $connection = 'tenant';

    protected $fillable = [
        'menu_item_id', 'name', 'min_selections', 'max_selections', 'is_required', 'sort_order'
    ];

    public function menuItem()
    {
        return $this->belongsTo(MenuItem::class);
    }

    public function comboItems()
    {
        return $this->hasMany(MenuItemComboItem::class, 'combo_group_id');
    }
}
