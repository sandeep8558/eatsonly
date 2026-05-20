<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class StockLedgerEntry extends Model
{
    use HasFactory, HasUuids;

    protected $connection = 'tenant';

    protected $table = 'stock_ledger_entries';

    protected $fillable = [
        'restaurant_id',
        'inventory_item_id',
        'transaction_type',
        'quantity',
        'cost_per_unit',
        'unit',
        'batch_number',
        'expiry_date',
        'remaining_qty',
        'reference_id',
    ];

    public function inventoryItem()
    {
        return $this->belongsTo(InventoryItem::class, 'inventory_item_id');
    }
}
