<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class TaxGroup extends Model
{
    use HasFactory, HasUuids;

    protected $connection = 'tenant';

    protected $fillable = [
        'name',
        'is_active',
        'is_inclusive',
    ];

    /**
     * Get the taxes for the tax group.
     */
    public function taxes(): HasMany
    {
        return $this->hasMany(Tax::class);
    }
}
