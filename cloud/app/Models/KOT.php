<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class KOT extends Model
{
    use HasFactory, HasUuids;

    protected $connection = 'tenant';
    protected $table = 'kots';

    protected $fillable = [
        'order_id',
        'kds_station_id',
        'restaurant_id',
        'status'
    ];

    public function order()
    {
        return $this->belongsTo(Order::class, 'order_id');
    }

    public function kdsStation()
    {
        return $this->belongsTo(KDSStation::class, 'kds_station_id');
    }

    public function items()
    {
        return $this->hasMany(OrderItem::class, 'kot_id');
    }
}
