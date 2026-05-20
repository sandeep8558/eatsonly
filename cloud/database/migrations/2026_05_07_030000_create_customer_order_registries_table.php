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
        Schema::create('customer_order_registries', function (Blueprint $table) {
            $table->id();
            $table->foreignUuid('customer_id')->nullable()->constrained('users')->onDelete('set null');
            $table->unsignedBigInteger('restaurant_id')->index();
            $table->uuid('tenant_order_id')->index();
            $table->string('restaurant_name');
            $table->string('restaurant_logo')->nullable();
            $table->text('items_summary')->nullable();
            $table->string('status')->default('open'); // open, billed, paid, completed
            $table->decimal('total', 10, 2)->default(0);
            $table->string('order_type')->default('delivery'); // dine-in, takeaway, delivery
            $table->timestamps();
            
            // Add unique index constraint to prevent duplicate order indexing
            $table->unique(['restaurant_id', 'tenant_order_id']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('customer_order_registries');
    }
};
