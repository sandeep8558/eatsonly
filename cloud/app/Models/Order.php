<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Order extends Model
{
    use HasFactory, HasUuids;

    protected $connection = 'tenant';

    protected $fillable = [
        'restaurant_id',
        'table_id',
        'user_id',
        'order_type',
        'customer_name',
        'customer_phone',
        'delivery_address',
        'customer_id',
        'source',
        'status',
        'payment_method',
        'subtotal',
        'discount_amount',
        'discount_percentage',
        'discount_type',
        'discount_reason',
        'tax',
        'total',
        'tip_amount',
        'delivery_charge',
        'packing_charge',
        'service_charge',
        'delivery_staff_id',
        'delivery_status',
        'dispatched_at',
        'delivered_at'
    ];

    public function customer()
    {
        return $this->belongsTo(User::class, 'customer_id');
    }

    public function items()
    {
        return $this->hasMany(OrderItem::class, 'order_id');
    }

    public function table()
    {
        return $this->belongsTo(RestaurantTable::class, 'table_id');
    }

    public function payments()
    {
        return $this->hasMany(OrderPayment::class, 'order_id');
    }

    public function deliveryStaff()
    {
        return $this->belongsTo(User::class, 'delivery_staff_id');
    }

    /**
     * Synchronizes this tenant order to the master CustomerOrderRegistry table.
     */
    public function syncToCentralRegistry()
    {
        try {
            // 1. Fetch restaurant from the central/master database
            $restaurant = \App\Models\Restaurant::find($this->restaurant_id);
            if (!$restaurant) {
                return;
            }

            // 2. Build the order items summary
            $items = \App\Models\OrderItem::with('menuItem')
                ->where('order_id', $this->id)
                ->whereNull('parent_order_item_id')
                ->get();

            $summaryParts = [];
            foreach ($items as $item) {
                $itemName = $item->menuItem ? $item->menuItem->name : 'Item';
                $summaryParts[] = "{$item->quantity}x {$itemName}";
            }
            $itemsSummary = implode(', ', $summaryParts);

            // Query destination coordinates from customer addresses table in mysql database
            $deliveryLat = null;
            $deliveryLng = null;
            if ($this->customer_id) {
                $address = \Illuminate\Support\Facades\DB::connection('mysql')->table('addresses')
                    ->where('user_id', $this->customer_id)
                    ->orderBy('is_default', 'desc')
                    ->first();
                if ($address) {
                    $deliveryLat = $address->latitude;
                    $deliveryLng = $address->longitude;
                }
            }

            // 3. Upsert into the master registry table
            \App\Models\CustomerOrderRegistry::updateOrCreate(
                [
                    'restaurant_id' => $this->restaurant_id,
                    'tenant_order_id' => $this->id,
                ],
                [
                    'customer_id' => $this->customer_id,
                    'restaurant_name' => $restaurant->name,
                    'restaurant_logo' => $restaurant->logo,
                    'items_summary' => $itemsSummary ?: 'Standard Items',
                    'status' => $this->status,
                    'total' => $this->total,
                    'order_type' => $this->order_type,
                    'delivery_latitude' => $deliveryLat,
                    'delivery_longitude' => $deliveryLng,
                    'created_at' => $this->created_at ?? now(),
                    'updated_at' => $this->updated_at ?? now(),
                ]
            );
        } catch (\Exception $e) {
            \Illuminate\Support\Facades\Log::error("Failed to sync order to central registry: " . $e->getMessage());
        }
    }
}
