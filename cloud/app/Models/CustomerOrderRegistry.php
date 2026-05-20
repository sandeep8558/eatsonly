<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class CustomerOrderRegistry extends Model
{
    protected $connection = 'mysql';

    protected $fillable = [
        'customer_id',
        'restaurant_id',
        'tenant_order_id',
        'restaurant_name',
        'restaurant_logo',
        'items_summary',
        'status',
        'total',
        'order_type',
        'rider_latitude',
        'rider_longitude',
        'delivery_latitude',
        'delivery_longitude',
    ];

    /**
     * Get the customer that placed the order.
     */
    public function customer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'customer_id');
    }

    /**
     * Get the restaurant where the order was placed.
     */
    public function restaurant(): BelongsTo
    {
        return $this->belongsTo(Restaurant::class, 'restaurant_id');
    }
}
