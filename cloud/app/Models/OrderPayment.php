<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class OrderPayment extends Model
{
    use HasFactory, HasUuids;

    protected $connection = 'tenant';
    protected $table = 'payments';

    protected $fillable = [
        'order_id',
        'amount',
        'tip_amount',
        'payment_method',
        'transaction_id',
        'notes'
    ];

    public function order()
    {
        return $this->belongsTo(Order::class);
    }
}
