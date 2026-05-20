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
        Schema::connection('mysql')->table('customer_order_registries', function (Blueprint $table) {
            $table->decimal('rider_latitude', 10, 8)->nullable()->after('order_type');
            $table->decimal('rider_longitude', 11, 8)->nullable()->after('rider_latitude');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::connection('mysql')->table('customer_order_registries', function (Blueprint $table) {
            $table->dropColumn(['rider_latitude', 'rider_longitude']);
        });
    }
};
