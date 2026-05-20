<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class InventoryItem extends Model
{
    use HasFactory, HasUuids;

    protected $connection = 'tenant';

    protected $table = 'inventory_items';

    protected $fillable = [
        'restaurant_id',
        'name',
        'sku',
        'category',
        'quantity',
        'unit',
        'min_threshold',
        'cost_per_unit',
        'storage_location',
        'expiry_date',
    ];
}
