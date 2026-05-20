<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class InventoryCategory extends Model
{
    use HasFactory, HasUuids;

    protected $connection = 'tenant';

    protected $table = 'inventory_categories';

    protected $fillable = [
        'restaurant_id',
        'name',
    ];
}
