<?php
  
namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class KDSStation extends Model
{
    use HasFactory, HasUuids;

    protected $connection = 'tenant';
    protected $table = 'kds_stations';

    protected $fillable = [
        'restaurant_id',
        'name',
        'printer_ip',
        'printer_port',
        'is_active'
    ];


    public function categories()
    {
        return $this->hasMany(MenuCategory::class, 'kds_station_id');
    }

    public function kots()
    {
        return $this->hasMany(KOT::class, 'kds_station_id');
    }
}
