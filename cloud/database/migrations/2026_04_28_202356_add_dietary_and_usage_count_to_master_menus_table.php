<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('master_menus', function (Blueprint $table) {
            $table->boolean('is_veg')->default(true)->after('is_active');
            $table->boolean('is_nonveg')->default(true)->after('is_veg');
            $table->boolean('is_jain')->default(false)->after('is_nonveg');
            $table->unsignedInteger('usage_count')->default(0)->after('is_jain');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('master_menus', function (Blueprint $table) {
            $table->dropColumn(['is_veg', 'is_nonveg', 'is_jain', 'usage_count']);
        });
    }
};
