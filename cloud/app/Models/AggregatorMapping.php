<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class AggregatorMapping extends Model
{
    use HasUuids;

    protected $connection = 'tenant';

    protected $fillable = [
        'menu_item_id',
        'aggregator',
        'external_item_id',
        'external_price',
        'is_synced',
    ];

    protected $casts = [
        'external_price' => 'decimal:2',
        'is_synced' => 'boolean',
    ];

    /**
     * Get the menu item associated with this mapping.
     */
    public function menuItem(): BelongsTo
    {
        return $this->belongsTo(MenuItem::class);
    }
}
