<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class AggregatorOrder extends Model
{
    use HasUuids;

    protected $connection = 'tenant';

    protected $fillable = [
        'order_id',
        'aggregator',
        'external_order_id',
        'rider_name',
        'rider_phone',
        'raw_payload',
    ];

    protected $casts = [
        'raw_payload' => 'array',
    ];

    /**
     * Get the order associated with this aggregator record.
     */
    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class);
    }
}
