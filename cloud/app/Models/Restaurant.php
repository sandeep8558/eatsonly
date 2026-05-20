<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Restaurant extends Model
{
    protected $connection = 'mysql';

    protected $fillable = [
        'user_id',
        'name',
        'upi_id',
        'slug',
        'address',
        'logo',
        'is_active',
        'is_veg',
        'is_nonveg',
        'is_jain',
        'takeaway_menu_card_id',
        'delivery_menu_card_id',
        'tax_name',
        'tax_registration_number',
        'fssai_number',
        'latitude',
        'longitude',
        'is_delivery',
        'is_takeaway',
        'is_dinein',
        'bill_printer_ip',
        'bill_printer_port'
    ];


    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
