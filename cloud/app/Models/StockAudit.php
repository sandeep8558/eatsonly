<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class StockAudit extends Model
{
    use HasUuids;

    protected $connection = 'tenant';

    protected $fillable = [
        'restaurant_id',
        'audited_by',
        'audit_date',
        'status',
    ];

    public function items()
    {
        return $this->hasMany(StockAuditItem::class, 'stock_audit_id');
    }

    public function auditor()
    {
        return $this->belongsTo(User::class, 'audited_by');
    }
}
