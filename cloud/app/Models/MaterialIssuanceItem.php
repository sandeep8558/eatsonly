<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class MaterialIssuanceItem extends Model
{
    use HasFactory, HasUuids;

    protected $connection = 'tenant';

    protected $table = 'material_issuance_items';

    protected $fillable = [
        'material_issuance_id',
        'inventory_item_id',
        'quantity',
        'unit',
    ];

    public function materialIssuance()
    {
        return $this->belongsTo(MaterialIssuance::class, 'material_issuance_id');
    }

    public function inventoryItem()
    {
        return $this->belongsTo(InventoryItem::class, 'inventory_item_id');
    }
}
