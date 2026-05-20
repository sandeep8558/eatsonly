<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class MasterMenu extends Model
{
    use HasFactory, HasUuids, SoftDeletes;

    protected $fillable = ['name', 'description', 'image', 'is_active', 'is_veg', 'is_nonveg', 'is_jain', 'usage_count'];

    public function categories()
    {
        return $this->belongsToMany(MasterCategory::class, 'master_category_master_menu');
    }
}
