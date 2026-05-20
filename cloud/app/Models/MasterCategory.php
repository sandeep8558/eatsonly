<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class MasterCategory extends Model
{
    use HasFactory, HasUuids, SoftDeletes;

    protected $fillable = ['name', 'image', 'is_active', 'usage_count'];

    public function menus()
    {
        return $this->belongsToMany(MasterMenu::class, 'master_category_master_menu');
    }
}
