<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class WastageEntry extends Model
{
    use HasFactory, HasUuids;

    protected $connection = 'tenant';

    protected $table = 'wastage_entries';

    protected $fillable = [
        'restaurant_id',
        'inventory_item_id',
        'quantity',
        'unit',
        'reason',
        'logged_by',
        'notes',
    ];

    public function inventoryItem()
    {
        return $this->belongsTo(InventoryItem::class, 'inventory_item_id');
    }

    public function user()
    {
        return $this->belongsTo(User::class, 'logged_by');
    }
}
