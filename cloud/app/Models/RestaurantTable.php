<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class RestaurantTable extends Model
{
    use HasFactory, HasUuids;

    protected $connection = 'tenant';
    protected $table = 'tables';

    protected $fillable = [
        'floor_id', 
        'name', 
        'capacity', 
        'shape', 
        'x_pos', 
        'y_pos', 
        'status'
    ];

    public function floor()
    {
        return $this->belongsTo(Floor::class);
    }
}
