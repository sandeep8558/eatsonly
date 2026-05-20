<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class MaterialIssuance extends Model
{
    use HasFactory, HasUuids;

    protected $connection = 'tenant';

    protected $table = 'material_issuances';

    protected $fillable = [
        'restaurant_id',
        'issued_by',
        'received_by',
        'department',
        'notes',
    ];

    public function items()
    {
        return $this->hasMany(MaterialIssuanceItem::class, 'material_issuance_id');
    }

    public function issuer()
    {
        return $this->belongsTo(User::class, 'issued_by');
    }

    public function receiver()
    {
        return $this->belongsTo(User::class, 'received_by');
    }
}
