<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;

#[Fillable(['name', 'monthly_price', 'yearly_price', 'description', 'outlets', 'is_outlets_fixed', 'list', 'is_active'])]
class PricingPlan extends Model
{
    /** @use HasFactory<\Database\Factories\PricingPlanFactory> */
    use HasFactory;

    protected $casts = [
        'list' => 'array',
        'monthly_price' => 'decimal:2',
        'yearly_price' => 'decimal:2',
        'outlets' => 'integer',
        'is_outlets_fixed' => 'boolean',
        'is_active' => 'boolean',
    ];
}
