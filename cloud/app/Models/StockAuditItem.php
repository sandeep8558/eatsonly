<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class StockAuditItem extends Model
{
    use HasUuids;

    protected $connection = 'tenant';

    protected $fillable = [
        'stock_audit_id',
        'inventory_item_id',
        'theoretical_qty',
        'physical_qty',
        'variance',
        'cost_variance',
    ];

    public function audit()
    {
        return $this->belongsTo(StockAudit::class, 'stock_audit_id');
    }

    public function inventoryItem()
    {
        return $this->belongsTo(InventoryItem::class, 'inventory_item_id');
    }
}
