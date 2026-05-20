<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Supplier extends Model
{
    use HasFactory, HasUuids;

    protected $connection = 'tenant';

    protected $table = 'suppliers';

    protected $fillable = [
        'restaurant_id',
        'name',
        'contact_person',
        'phone',
        'email',
        'address',
    ];

    public function purchases()
    {
        return $this->hasMany(PurchaseOrder::class, 'supplier_id');
    }
}
