<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class MenuItem extends Model
{
    use HasFactory, HasUuids;

    protected $connection = 'tenant';

    protected $fillable = [
        'menu_category_id', 'tax_group_id', 'name', 'description', 'price', 'type',
        'is_veg', 'is_nonveg', 'is_jain', 'image', 'sort_order', 'is_available'
    ];

    public function category()
    {
        return $this->belongsTo(MenuCategory::class, 'menu_category_id');
    }

    public function taxGroup()
    {
        return $this->belongsTo(TaxGroup::class, 'tax_group_id');
    }

    public function comboGroups()
    {
        return $this->hasMany(MenuItemComboGroup::class, 'menu_item_id')->orderBy('sort_order');
    }

}
