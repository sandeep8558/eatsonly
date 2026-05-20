<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class OrderItem extends Model
{
    use HasFactory, HasUuids;

    protected $connection = 'tenant';

    protected $fillable = [
        'order_id',
        'parent_order_item_id',
        'combo_group_id',
        'kot_id',
        'menu_item_id',
        'quantity',
        'price',
        'status',
        'notes'
    ];

    public function kot()
    {
        return $this->belongsTo(KOT::class, 'kot_id');
    }

    public function order()
    {
        return $this->belongsTo(Order::class, 'order_id');
    }

    public function menuItem()
    {
        return $this->belongsTo(MenuItem::class, 'menu_item_id');
    }

    public function parent()
    {
        return $this->belongsTo(OrderItem::class, 'parent_order_item_id');
    }

    public function children()
    {
        return $this->hasMany(OrderItem::class, 'parent_order_item_id');
    }

    public function comboGroup()
    {
        return $this->belongsTo(MenuItemComboGroup::class, 'combo_group_id');
    }

}
