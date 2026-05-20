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
        Schema::table('restaurants', function (Blueprint $table) {
            $table->boolean('is_delivery')->default(true)->after('longitude');
            $table->boolean('is_takeaway')->default(true)->after('is_delivery');
            $table->boolean('is_dinein')->default(true)->after('is_takeaway');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('restaurants', function (Blueprint $table) {
            $table->dropColumn(['is_delivery', 'is_takeaway', 'is_dinein']);
        });
    }
};
