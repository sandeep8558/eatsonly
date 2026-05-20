<?php

namespace App\Services;

use App\Models\Restaurant;
use App\Models\User;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Config;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class TenantService
{
    /**
     * Ensure the tenant database exists and has the required schema.
     */
    public function ensureTenantDatabase($user)
    {
        if (!$user) {
            return config('database.connections.mysql.database');
        }

        $owner = $user;
        $link = DB::table('restaurant_user')->where('user_id', $user->id)->first();
        if ($link) {
            $restaurant = DB::table('restaurants')->where('id', $link->restaurant_id)->first();
            if ($restaurant && $restaurant->user_id !== $user->id) {
                $resolvedOwner = User::find($restaurant->user_id);
                if ($resolvedOwner) {
                    $owner = $resolvedOwner;
                }
            }
        }

        // Only create or sync databases for Restaurant Owners (admin) or Super Admins
        if (!$owner->isRestaurant() && !$owner->isSuperAdmin()) {
            return config('database.connections.mysql.database');
        }

        $dbName = 'resto_'.str_replace('-', '_', $owner->id);

        // 1. Create database if not exists
        DB::statement("CREATE DATABASE IF NOT EXISTS `{$dbName}` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci");

        // 2. Set the tenant connection to use this database
        $this->switchToTenant($dbName);

        // 3. Ensure tables exist in the tenant database
        $this->syncSchema($owner);

        // 4. Update user record with database name
        if ($user->database_name !== $dbName) {
            $user->update(['database_name' => $dbName]);
        }

        // 5. Create tenant storage directory
        $tenantPath = storage_path('app/public/tenants/'.$dbName);
        if (! file_exists($tenantPath)) {
            mkdir($tenantPath, 0755, true);
        }

        return $dbName;
    }

    /**
     * Switch the 'tenant' connection to a specific database.
     */
    public function switchToTenant($dbName)
    {
        Config::set('database.connections.tenant.database', $dbName);
        DB::purge('tenant');
        DB::reconnect('tenant');
    }

    /**
     * Sync the required tables to the tenant database.
     */
    public function syncSchema($user = null)
    {
        $colsAdded = false;
        if (! Schema::connection('tenant')->hasTable('restaurants')) {
            Schema::connection('tenant')->create('restaurants', function (Blueprint $table) {
                $table->id();
                $table->foreignUuid('user_id')->nullable();
                $table->string('name');
                $table->string('slug')->unique();
                $table->string('logo')->nullable();
                $table->boolean('is_veg')->default(true);
                $table->boolean('is_nonveg')->default(true);
                $table->boolean('is_jain')->default(false);
                $table->string('upi_id')->nullable();
                $table->text('address')->nullable();
                $table->string('tax_name')->nullable();
                $table->string('tax_registration_number')->nullable();
                $table->string('fssai_number')->nullable();
                $table->decimal('latitude', 10, 8)->nullable();
                $table->decimal('longitude', 11, 8)->nullable();
                $table->boolean('is_delivery')->default(true);
                $table->boolean('is_takeaway')->default(true);
                $table->boolean('is_dinein')->default(true);
                $table->string('bill_printer_ip')->nullable();
                $table->integer('bill_printer_port')->default(9100);
                $table->timestamps();
            });
            $colsAdded = true;
        } else {
            // Add columns if they do not exist in an existing tenant database
            if (! Schema::connection('tenant')->hasColumn('restaurants', 'is_veg')) {
                Schema::connection('tenant')->table('restaurants', function (Blueprint $table) {
                    $table->boolean('is_veg')->default(true)->after('logo');
                    $table->boolean('is_nonveg')->default(true)->after('is_veg');
                });
            }
            if (! Schema::connection('tenant')->hasColumn('restaurants', 'is_jain')) {
                Schema::connection('tenant')->table('restaurants', function (Blueprint $table) {
                    $table->boolean('is_jain')->default(false)->after('is_nonveg');
                });
            }
            if (! Schema::connection('tenant')->hasColumn('restaurants', 'upi_id')) {
                Schema::connection('tenant')->table('restaurants', function (Blueprint $table) {
                    $table->string('upi_id')->nullable()->after('name');
                });
            }
            if (! Schema::connection('tenant')->hasColumn('restaurants', 'takeaway_menu_card_id')) {
                Schema::connection('tenant')->table('restaurants', function (Blueprint $table) {
                    $table->uuid('takeaway_menu_card_id')->nullable()->after('upi_id');
                    $table->uuid('delivery_menu_card_id')->nullable()->after('takeaway_menu_card_id');
                });
            }
            if (! Schema::connection('tenant')->hasColumn('restaurants', 'tax_name')) {
                Schema::connection('tenant')->table('restaurants', function (Blueprint $table) {
                    $table->string('tax_name')->nullable()->after('address');
                    $table->string('tax_registration_number')->nullable()->after('tax_name');
                    $table->string('fssai_number')->nullable()->after('tax_registration_number');
                });
                $colsAdded = true;
            }
            if (! Schema::connection('tenant')->hasColumn('restaurants', 'bill_printer_ip')) {
                Schema::connection('tenant')->table('restaurants', function (Blueprint $table) {
                    $table->string('bill_printer_ip')->nullable()->after('address');
                    $table->integer('bill_printer_port')->default(9100)->after('bill_printer_ip');
                });
                $colsAdded = true;
            }
            if (! Schema::connection('tenant')->hasColumn('restaurants', 'latitude')) {
                Schema::connection('tenant')->table('restaurants', function (Blueprint $table) {
                    $table->decimal('latitude', 10, 8)->nullable()->after('fssai_number');
                    $table->decimal('longitude', 11, 8)->nullable()->after('latitude');
                });
                $colsAdded = true;
            }
            if (! Schema::connection('tenant')->hasColumn('restaurants', 'is_delivery')) {
                Schema::connection('tenant')->table('restaurants', function (Blueprint $table) {
                    $table->boolean('is_delivery')->default(true)->after('longitude');
                    $table->boolean('is_takeaway')->default(true)->after('is_delivery');
                    $table->boolean('is_dinein')->default(true)->after('is_takeaway');
                });
                $colsAdded = true;
            }
        }

        // If columns were added and we have a user, sync all restaurants
        if ($colsAdded && $user) {
            $restaurants = Restaurant::where('user_id', $user->id)->get();
            foreach ($restaurants as $resto) {
                $this->syncRestaurantToTenant($user, $resto->toArray());
            }
        }

        // Menu Cards
        if (! Schema::connection('tenant')->hasTable('menu_cards')) {
            Schema::connection('tenant')->create('menu_cards', function (Blueprint $table) {
                $table->uuid('id')->primary();
                $table->string('name');
                $table->boolean('is_active')->default(true);
                $table->timestamps();
            });
        } elseif (Schema::connection('tenant')->hasColumn('menu_cards', 'restaurant_id')) {
            Schema::connection('tenant')->table('menu_cards', function (Blueprint $table) {
                $table->dropColumn('restaurant_id');
            });
        }

        // PURGE: Pivot table for Restaurants and Menu Cards (We are moving to Floor-wise menu)
        if (Schema::connection('tenant')->hasTable('menu_card_restaurant')) {
            Schema::connection('tenant')->drop('menu_card_restaurant');
        }

        // Menu Categories
        if (! Schema::connection('tenant')->hasTable('menu_categories')) {
            Schema::connection('tenant')->create('menu_categories', function (Blueprint $table) {
                $table->uuid('id')->primary();
                $table->uuid('menu_card_id')->index();
                $table->uuid('kds_station_id')->nullable()->index();
                $table->string('name');
                $table->integer('sort_order')->default(0);
                $table->boolean('is_active')->default(true);
                $table->timestamps();
            });
        } else {
            if (! Schema::connection('tenant')->hasColumn('menu_categories', 'kds_station_id')) {
                Schema::connection('tenant')->table('menu_categories', function (Blueprint $table) {
                    $table->uuid('kds_station_id')->nullable()->index()->after('menu_card_id');
                });
            }
        }

        // Menu Items
        if (! Schema::connection('tenant')->hasTable('menu_items')) {
            Schema::connection('tenant')->create('menu_items', function (Blueprint $table) {
                $table->uuid('id')->primary();
                $table->uuid('menu_category_id')->index();
                $table->uuid('tax_group_id')->nullable()->index();
                $table->string('name');
                $table->text('description')->nullable();
                $table->decimal('price', 10, 2)->default(0);
                $table->string('type')->default('regular'); // regular, combo
                $table->boolean('is_veg')->default(true);
                $table->boolean('is_nonveg')->default(true);
                $table->boolean('is_jain')->default(false);
                $table->string('image')->nullable();
                $table->integer('sort_order')->default(0);
                $table->boolean('is_available')->default(true);
                $table->timestamps();
            });
        } else {
            if (! Schema::connection('tenant')->hasColumn('menu_items', 'tax_group_id')) {
                Schema::connection('tenant')->table('menu_items', function (Blueprint $table) {
                    $table->uuid('tax_group_id')->nullable()->index()->after('menu_category_id');
                });
            }
            if (! Schema::connection('tenant')->hasColumn('menu_items', 'type')) {
                Schema::connection('tenant')->table('menu_items', function (Blueprint $table) {
                    $table->string('type')->default('regular')->after('price');
                });
            }
        }

        // Combo Groups
        if (! Schema::connection('tenant')->hasTable('menu_item_combo_groups')) {
            Schema::connection('tenant')->create('menu_item_combo_groups', function (Blueprint $table) {
                $table->uuid('id')->primary();
                $table->uuid('menu_item_id')->index();
                $table->string('name');
                $table->integer('min_selections')->default(1);
                $table->integer('max_selections')->default(1);
                $table->boolean('is_required')->default(true);
                $table->integer('sort_order')->default(0);
                $table->timestamps();
            });
        }

        // Combo Items
        if (! Schema::connection('tenant')->hasTable('menu_item_combo_items')) {
            Schema::connection('tenant')->create('menu_item_combo_items', function (Blueprint $table) {
                $table->uuid('id')->primary();
                $table->uuid('combo_group_id')->index();
                $table->uuid('menu_item_id')->index();
                $table->decimal('extra_price', 10, 2)->default(0);
                $table->integer('quantity')->default(1);
                $table->boolean('is_default')->default(false);
                $table->timestamps();
            });
        }

        // Floor Plans
        if (! Schema::connection('tenant')->hasTable('floors')) {
            Schema::connection('tenant')->create('floors', function (Blueprint $table) {
                $table->uuid('id')->primary();
                $table->unsignedBigInteger('restaurant_id')->index();
                $table->uuid('menu_card_id')->nullable()->index();
                $table->string('name');
                $table->integer('sort_order')->default(0);
                $table->timestamps();
            });
        } else {
            if (! Schema::connection('tenant')->hasColumn('floors', 'menu_card_id')) {
                Schema::connection('tenant')->table('floors', function (Blueprint $table) {
                    $table->uuid('menu_card_id')->nullable()->index()->after('restaurant_id');
                });
            }
        }

        // Tables
        if (! Schema::connection('tenant')->hasTable('tables')) {
            Schema::connection('tenant')->create('tables', function (Blueprint $table) {
                $table->uuid('id')->primary();
                $table->uuid('floor_id')->index();
                $table->string('name');
                $table->integer('capacity')->default(2);
                $table->string('shape')->default('square');
                $table->double('x_pos')->default(0);
                $table->double('y_pos')->default(0);
                $table->string('status')->default('available');
                $table->timestamps();
            });
        }

        // Staff Attendance
        if (! Schema::connection('tenant')->hasTable('attendances')) {
            Schema::connection('tenant')->create('attendances', function (Blueprint $table) {
                $table->id();
                $table->uuid('user_id')->index(); // Link to master user ID
                $table->unsignedBigInteger('restaurant_id')->index();
                $table->timestamp('clock_in');
                $table->timestamp('clock_out')->nullable();
                $table->string('status')->default('present'); // present, break, etc.
                $table->text('notes')->nullable();
                $table->timestamps();
            });
        }

        // Taxation Framework
        if (! Schema::connection('tenant')->hasTable('tax_groups')) {
            Schema::connection('tenant')->create('tax_groups', function (Blueprint $table) {
                $table->uuid('id')->primary();
                $table->string('name');
                $table->boolean('is_active')->default(true);
                $table->boolean('is_inclusive')->default(false);
                $table->timestamps();
            });
        }

        if (! Schema::connection('tenant')->hasTable('taxes')) {
            Schema::connection('tenant')->create('taxes', function (Blueprint $table) {
                $table->uuid('id')->primary();
                $table->foreignUuid('tax_group_id')->constrained('tax_groups')->onDelete('cascade');
                $table->string('name');
                $table->decimal('percentage', 5, 2);
                $table->timestamps();
            });
        }

        // KDS Stations
        if (! Schema::connection('tenant')->hasTable('kds_stations')) {
            Schema::connection('tenant')->create('kds_stations', function (Blueprint $table) {
                $table->uuid('id')->primary();
                $table->unsignedBigInteger('restaurant_id')->index();
                $table->string('name');
                $table->string('printer_ip')->nullable();
                $table->integer('printer_port')->default(9100);
                $table->boolean('is_active')->default(true);
                $table->timestamps();
            });
        } else {
            if (! Schema::connection('tenant')->hasColumn('kds_stations', 'printer_ip')) {
                Schema::connection('tenant')->table('kds_stations', function (Blueprint $table) {
                    $table->string('printer_ip')->nullable()->after('name');
                    $table->integer('printer_port')->default(9100)->after('printer_ip');
                });
            }
        }

        // Orders
        if (! Schema::connection('tenant')->hasTable('orders')) {
            Schema::connection('tenant')->create('orders', function (Blueprint $table) {
                $table->uuid('id')->primary();
                $table->unsignedBigInteger('restaurant_id')->index();
                $table->uuid('table_id')->nullable()->index();
                $table->uuid('user_id')->nullable()->index(); // Waiter ID
                $table->string('order_type')->default('dine-in'); // dine-in, takeaway, delivery
                $table->string('customer_name')->nullable();
                $table->string('customer_phone')->nullable();
                $table->text('delivery_address')->nullable();
                $table->string('status')->default('open'); // open, billed, paid
                $table->string('payment_method')->nullable();
                $table->decimal('subtotal', 10, 2)->default(0);
                $table->decimal('discount_amount', 10, 2)->default(0);
                $table->decimal('discount_percentage', 5, 2)->default(0);
                $table->string('discount_type')->nullable(); // fixed, percentage
                $table->string('discount_reason')->nullable();
                $table->decimal('tax', 10, 2)->default(0);
                $table->decimal('total', 10, 2)->default(0);
                $table->decimal('tip_amount', 10, 2)->default(0);
                $table->decimal('delivery_charge', 10, 2)->default(0);
                $table->decimal('packing_charge', 10, 2)->default(0);
                $table->decimal('service_charge', 10, 2)->default(0);
                $table->uuid('delivery_staff_id')->nullable()->index();
                $table->string('delivery_status')->default('pending'); // pending, assigned, picked_up, delivered
                $table->timestamp('dispatched_at')->nullable();
                $table->timestamp('delivered_at')->nullable();
                $table->timestamps();
            });
        } else {
            if (! Schema::connection('tenant')->hasColumn('orders', 'delivery_charge')) {
                Schema::connection('tenant')->table('orders', function (Blueprint $table) {
                    $table->decimal('delivery_charge', 10, 2)->default(0)->after('tip_amount');
                    $table->decimal('packing_charge', 10, 2)->default(0)->after('delivery_charge');
                    $table->decimal('service_charge', 10, 2)->default(0)->after('packing_charge');
                });
            }
            if (! Schema::connection('tenant')->hasColumn('orders', 'payment_method')) {
                Schema::connection('tenant')->table('orders', function (Blueprint $table) {
                    $table->string('payment_method')->nullable()->after('status');
                });
            }
            if (! Schema::connection('tenant')->hasColumn('orders', 'order_type')) {
                Schema::connection('tenant')->table('orders', function (Blueprint $table) {
                    $table->uuid('table_id')->nullable()->change();
                    $table->string('order_type')->default('dine-in')->after('user_id');
                    $table->string('customer_name')->nullable()->after('order_type');
                    $table->string('customer_phone')->nullable()->after('customer_name');
                    $table->text('delivery_address')->nullable()->after('customer_phone');
                });
            }
            if (! Schema::connection('tenant')->hasColumn('orders', 'discount_amount')) {
                Schema::connection('tenant')->table('orders', function (Blueprint $table) {
                    $table->decimal('discount_amount', 10, 2)->default(0)->after('subtotal');
                    $table->decimal('discount_percentage', 5, 2)->default(0)->after('discount_amount');
                    $table->string('discount_type')->nullable()->after('discount_percentage');
                    $table->string('discount_reason')->nullable()->after('discount_type');
                });
            }
            if (! Schema::connection('tenant')->hasColumn('orders', 'tip_amount')) {
                Schema::connection('tenant')->table('orders', function (Blueprint $table) {
                    $table->decimal('tip_amount', 10, 2)->default(0)->after('total');
                });
            }
            if (! Schema::connection('tenant')->hasColumn('orders', 'source')) {
                Schema::connection('tenant')->table('orders', function (Blueprint $table) {
                    $table->string('source')->default('pos_waiter')->after('restaurant_id');
                    $table->uuid('customer_id')->nullable()->index()->after('source');
                });
            }
            if (! Schema::connection('tenant')->hasColumn('orders', 'created_by_id')) {
                Schema::connection('tenant')->table('orders', function (Blueprint $table) {
                    $table->uuid('created_by_id')->nullable()->index()->after('user_id');
                    $table->string('created_by_type')->nullable()->after('created_by_id');
                });
            }
            if (! Schema::connection('tenant')->hasColumn('orders', 'delivery_staff_id')) {
                Schema::connection('tenant')->table('orders', function (Blueprint $table) {
                    $table->uuid('delivery_staff_id')->nullable()->index()->after('tip_amount');
                    $table->string('delivery_status')->default('pending')->after('delivery_staff_id');
                    $table->timestamp('dispatched_at')->nullable()->after('delivery_status');
                    $table->timestamp('delivered_at')->nullable()->after('dispatched_at');
                });
            } else {
                // Ensure existing column is UUID type CHAR(36) instead of BigInt
                try {
                    DB::connection('tenant')->statement("ALTER TABLE `orders` MODIFY `delivery_staff_id` CHAR(36) NULL");
                } catch (\Exception $e) {
                    try {
                        Schema::connection('tenant')->table('orders', function (Blueprint $table) {
                            $table->uuid('delivery_staff_id')->nullable()->change();
                        });
                    } catch (\Exception $e2) {
                        \Illuminate\Support\Facades\Log::error("Failed to alter delivery_staff_id to uuid: " . $e2->getMessage());
                    }
                }
            }
        }

        // Order Items
        if (! Schema::connection('tenant')->hasTable('order_items')) {
            Schema::connection('tenant')->create('order_items', function (Blueprint $table) {
                $table->uuid('id')->primary();
                $table->uuid('order_id')->index();
                $table->uuid('parent_order_item_id')->nullable()->index();
                $table->uuid('combo_group_id')->nullable()->index();
                $table->uuid('kot_id')->nullable()->index();
                $table->uuid('menu_item_id')->index();
                $table->integer('quantity')->default(1);
                $table->decimal('price', 10, 2)->default(0);
                $table->string('status')->default('pending'); // pending, cooking, served
                $table->text('notes')->nullable();
                $table->timestamps();
            });
        } else {
            if (! Schema::connection('tenant')->hasColumn('order_items', 'kot_id')) {
                Schema::connection('tenant')->table('order_items', function (Blueprint $table) {
                    $table->uuid('kot_id')->nullable()->index()->after('order_id');
                });
            }
            if (! Schema::connection('tenant')->hasColumn('order_items', 'parent_order_item_id')) {
                Schema::connection('tenant')->table('order_items', function (Blueprint $table) {
                    $table->uuid('parent_order_item_id')->nullable()->index()->after('order_id');
                    $table->uuid('combo_group_id')->nullable()->index()->after('parent_order_item_id');
                });
            }
        }

        // KOTs (Kitchen Order Tickets)
        if (! Schema::connection('tenant')->hasTable('kots')) {
            Schema::connection('tenant')->create('kots', function (Blueprint $table) {
                $table->uuid('id')->primary();
                $table->uuid('order_id')->index();
                $table->uuid('kds_station_id')->nullable()->index();
                $table->unsignedBigInteger('restaurant_id')->index();
                $table->string('status')->default('pending'); // pending, cooking, completed
                $table->timestamps();
            });
        } else {
            if (! Schema::connection('tenant')->hasColumn('kots', 'kds_station_id')) {
                Schema::connection('tenant')->table('kots', function (Blueprint $table) {
                    $table->uuid('kds_station_id')->nullable()->index()->after('order_id');
                });
            }
        }

        // Settings
        if (! Schema::connection('tenant')->hasTable('settings')) {
            Schema::connection('tenant')->create('settings', function (Blueprint $table) {
                $table->id();
                $table->string('key')->unique();
                $table->text('value')->nullable();
                $table->string('group')->default('general');
                $table->timestamps();
            });

            // Seed default settings
            DB::connection('tenant')->table('settings')->insert([
                [
                    'key' => 'currency',
                    'value' => 'INR',
                    'group' => 'general',
                    'created_at' => now(),
                    'updated_at' => now(),
                ],
                // Takeaway Charges
                [
                    'key' => 'takeaway_packing_enabled',
                    'value' => 'no',
                    'group' => 'charges',
                    'created_at' => now(),
                    'updated_at' => now(),
                ],
                [
                    'key' => 'takeaway_packing_amount',
                    'value' => '0',
                    'group' => 'charges',
                    'created_at' => now(),
                    'updated_at' => now(),
                ],
                [
                    'key' => 'takeaway_service_enabled',
                    'value' => 'no',
                    'group' => 'charges',
                    'created_at' => now(),
                    'updated_at' => now(),
                ],
                [
                    'key' => 'takeaway_service_amount',
                    'value' => '0',
                    'group' => 'charges',
                    'created_at' => now(),
                    'updated_at' => now(),
                ],
                // Delivery Charges
                [
                    'key' => 'delivery_delivery_enabled',
                    'value' => 'no',
                    'group' => 'charges',
                    'created_at' => now(),
                    'updated_at' => now(),
                ],
                [
                    'key' => 'delivery_delivery_amount',
                    'value' => '0',
                    'group' => 'charges',
                    'created_at' => now(),
                    'updated_at' => now(),
                ],
                [
                    'key' => 'delivery_packing_enabled',
                    'value' => 'no',
                    'group' => 'charges',
                    'created_at' => now(),
                    'updated_at' => now(),
                ],
                [
                    'key' => 'delivery_packing_amount',
                    'value' => '0',
                    'group' => 'charges',
                    'created_at' => now(),
                    'updated_at' => now(),
                ],
                [
                    'key' => 'delivery_service_enabled',
                    'value' => 'no',
                    'group' => 'charges',
                    'created_at' => now(),
                    'updated_at' => now(),
                ],
                [
                    'key' => 'delivery_service_amount',
                    'value' => '0',
                    'group' => 'charges',
                    'created_at' => now(),
                    'updated_at' => now(),
                ],
                // Dine-in Charges
                [
                    'key' => 'dinein_packing_enabled',
                    'value' => 'no',
                    'group' => 'charges',
                    'created_at' => now(),
                    'updated_at' => now(),
                ],
                [
                    'key' => 'dinein_packing_amount',
                    'value' => '0',
                    'group' => 'charges',
                    'created_at' => now(),
                    'updated_at' => now(),
                ],
                [
                    'key' => 'dinein_service_enabled',
                    'value' => 'no',
                    'group' => 'charges',
                    'created_at' => now(),
                    'updated_at' => now(),
                ],
                [
                    'key' => 'dinein_service_amount',
                    'value' => '0',
                    'group' => 'charges',
                    'created_at' => now(),
                    'updated_at' => now(),
                ],
                [
                    'key' => 'tax_name_1',
                    'value' => 'CGST',
                    'group' => 'taxation',
                    'created_at' => now(),
                    'updated_at' => now(),
                ],
                [
                    'key' => 'tax_name_2',
                    'value' => 'SGST',
                    'group' => 'taxation',
                    'created_at' => now(),
                    'updated_at' => now(),
                ],
                [
                    'key' => 'tax_model',
                    'value' => 'inclusive',
                    'group' => 'taxation',
                    'created_at' => now(),
                    'updated_at' => now(),
                ],
            ]);
        }

        // Payments table for Split Payments
        if (! Schema::connection('tenant')->hasTable('payments')) {
            Schema::connection('tenant')->create('payments', function (Blueprint $table) {
                $table->uuid('id')->primary();
                $table->uuid('order_id')->index();
                $table->decimal('amount', 10, 2);
                $table->decimal('tip_amount', 10, 2)->default(0);
                $table->string('payment_method'); // cash, card, upi, wallet
                $table->string('transaction_id')->nullable();
                $table->text('notes')->nullable();
                $table->timestamps();
            });
        } else {
            if (! Schema::connection('tenant')->hasColumn('payments', 'tip_amount')) {
                Schema::connection('tenant')->table('payments', function (Blueprint $table) {
                    $table->decimal('tip_amount', 10, 2)->default(0)->after('amount');
                });
            }
        }

        // Inventory Categories
        if (! Schema::connection('tenant')->hasTable('inventory_categories')) {
            Schema::connection('tenant')->create('inventory_categories', function (Blueprint $table) {
                $table->uuid('id')->primary();
                $table->unsignedBigInteger('restaurant_id')->index();
                $table->string('name');
                $table->timestamps();
            });
        }

        // Inventory Items
        if (! Schema::connection('tenant')->hasTable('inventory_items')) {
            Schema::connection('tenant')->create('inventory_items', function (Blueprint $table) {
                $table->uuid('id')->primary();
                $table->unsignedBigInteger('restaurant_id')->index();
                $table->string('name');
                $table->string('sku')->nullable();
                $table->string('category');
                $table->decimal('quantity', 10, 2)->default(0.00);
                $table->string('unit');
                $table->decimal('min_threshold', 10, 2)->default(5.00);
                $table->decimal('cost_per_unit', 10, 2)->default(0.00);
                $table->string('storage_location')->default('Dry Storage'); // Dry Storage, Cold Storage, Freezer Storage
                $table->date('expiry_date')->nullable();
                $table->timestamps();
            });
        } else {
            if (! Schema::connection('tenant')->hasColumn('inventory_items', 'storage_location')) {
                Schema::connection('tenant')->table('inventory_items', function (Blueprint $table) {
                    $table->string('storage_location')->default('Dry Storage')->after('cost_per_unit');
                });
            }
            if (! Schema::connection('tenant')->hasColumn('inventory_items', 'expiry_date')) {
                Schema::connection('tenant')->table('inventory_items', function (Blueprint $table) {
                    $table->date('expiry_date')->nullable()->after('storage_location');
                });
            }
        }

        // Suppliers
        if (! Schema::connection('tenant')->hasTable('suppliers')) {
            Schema::connection('tenant')->create('suppliers', function (Blueprint $table) {
                $table->uuid('id')->primary();
                $table->unsignedBigInteger('restaurant_id')->index();
                $table->string('name');
                $table->string('contact_person')->nullable();
                $table->string('phone')->nullable();
                $table->string('email')->nullable();
                $table->text('address')->nullable();
                $table->timestamps();
            });
        }

        // Purchase Orders
        if (! Schema::connection('tenant')->hasTable('purchase_orders')) {
            Schema::connection('tenant')->create('purchase_orders', function (Blueprint $table) {
                $table->uuid('id')->primary();
                $table->unsignedBigInteger('restaurant_id')->index();
                $table->uuid('supplier_id')->index();
                $table->string('po_number')->unique();
                $table->string('status')->default('pending'); // pending, paid, cancelled
                $table->decimal('total_amount', 12, 2)->default(0.00);
                $table->timestamp('order_date')->useCurrent();
                $table->timestamps();
            });
        }

        // Purchase Order Items
        if (! Schema::connection('tenant')->hasTable('purchase_order_items')) {
            Schema::connection('tenant')->create('purchase_order_items', function (Blueprint $table) {
                $table->uuid('id')->primary();
                $table->uuid('purchase_order_id')->index();
                $table->uuid('inventory_item_id')->index();
                $table->decimal('quantity', 10, 2);
                $table->decimal('unit_price', 10, 2);
                $table->timestamps();
            });
        }

        // Recipes
        if (! Schema::connection('tenant')->hasTable('recipes')) {
            Schema::connection('tenant')->create('recipes', function (Blueprint $table) {
                $table->uuid('id')->primary();
                $table->uuid('menu_item_id')->index();
                $table->uuid('inventory_item_id')->index();
                $table->decimal('quantity_needed', 10, 4);
                $table->string('consumption_unit');
                $table->timestamps();
            });
        }

        // Stock Ledger Entries
        if (! Schema::connection('tenant')->hasTable('stock_ledger_entries')) {
            Schema::connection('tenant')->create('stock_ledger_entries', function (Blueprint $table) {
                $table->uuid('id')->primary();
                $table->integer('restaurant_id')->index();
                $table->uuid('inventory_item_id')->index();
                $table->string('transaction_type');
                $table->decimal('quantity', 12, 4);
                $table->decimal('cost_per_unit', 10, 2);
                $table->string('unit');
                $table->string('batch_number')->nullable();
                $table->date('expiry_date')->nullable();
                $table->decimal('remaining_qty', 12, 4)->default(0.0000);
                $table->uuid('reference_id')->nullable()->index();
                $table->timestamps();
            });
        }

        // Material Issuances
        if (! Schema::connection('tenant')->hasTable('material_issuances')) {
            Schema::connection('tenant')->create('material_issuances', function (Blueprint $table) {
                $table->uuid('id')->primary();
                $table->integer('restaurant_id')->index();
                $table->uuid('issued_by')->index();
                $table->uuid('received_by')->index();
                $table->string('department')->default('Main Kitchen');
                $table->text('notes')->nullable();
                $table->timestamps();
            });
        }

        // Material Issuance Items
        if (! Schema::connection('tenant')->hasTable('material_issuance_items')) {
            Schema::connection('tenant')->create('material_issuance_items', function (Blueprint $table) {
                $table->uuid('id')->primary();
                $table->uuid('material_issuance_id')->index();
                $table->uuid('inventory_item_id')->index();
                $table->decimal('quantity', 10, 2);
                $table->string('unit');
                $table->timestamps();
            });
        }

        // Wastage Entries
        if (! Schema::connection('tenant')->hasTable('wastage_entries')) {
            Schema::connection('tenant')->create('wastage_entries', function (Blueprint $table) {
                $table->uuid('id')->primary();
                $table->integer('restaurant_id')->index();
                $table->uuid('inventory_item_id')->index();
                $table->decimal('quantity', 10, 2);
                $table->string('unit');
                $table->string('reason');
                $table->uuid('logged_by')->index();
                $table->text('notes')->nullable();
                $table->timestamps();
            });
        }

        // Stock Audits
        if (! Schema::connection('tenant')->hasTable('stock_audits')) {
            Schema::connection('tenant')->create('stock_audits', function (Blueprint $table) {
                $table->uuid('id')->primary();
                $table->integer('restaurant_id')->index();
                $table->uuid('audited_by')->index();
                $table->date('audit_date');
                $table->enum('status', ['draft', 'submitted'])->default('draft');
                $table->timestamps();
            });
        }

        // Stock Audit Items
        if (! Schema::connection('tenant')->hasTable('stock_audit_items')) {
            Schema::connection('tenant')->create('stock_audit_items', function (Blueprint $table) {
                $table->uuid('id')->primary();
                $table->uuid('stock_audit_id')->index();
                $table->uuid('inventory_item_id')->index();
                $table->decimal('theoretical_qty', 12, 4);
                $table->decimal('physical_qty', 12, 4);
                $table->decimal('variance', 12, 4); // (Physical - Theoretical)
                $table->decimal('cost_variance', 10, 2);
                $table->timestamps();
            });
        }

        // Aggregator Menu Mappings
        if (! Schema::connection('tenant')->hasTable('aggregator_mappings')) {
            Schema::connection('tenant')->create('aggregator_mappings', function (Blueprint $table) {
                $table->uuid('id')->primary();
                $table->uuid('menu_item_id')->index();
                $table->string('aggregator'); // zomato, swiggy
                $table->string('external_item_id')->index();
                $table->decimal('external_price', 10, 2)->default(0);
                $table->boolean('is_synced')->default(true);
                $table->timestamps();

                $table->foreign('menu_item_id')->references('id')->on('menu_items')->onDelete('cascade');
                $table->unique(['menu_item_id', 'aggregator']);
            });
        }

        // Aggregator Order Information
        if (! Schema::connection('tenant')->hasTable('aggregator_orders')) {
            Schema::connection('tenant')->create('aggregator_orders', function (Blueprint $table) {
                $table->uuid('id')->primary();
                $table->uuid('order_id')->index();
                $table->string('aggregator'); // zomato, swiggy
                $table->string('external_order_id')->index();
                $table->string('rider_name')->nullable();
                $table->string('rider_phone')->nullable();
                $table->json('raw_payload')->nullable();
                $table->timestamps();

                $table->foreign('order_id')->references('id')->on('orders')->onDelete('cascade');
                $table->unique(['order_id', 'aggregator']);
            });
        }
    }

    /**
     * Sync a restaurant record to the tenant database.
     */
    public function syncRestaurantToTenant($user, $restaurantData)
    {
        $dbName = $this->ensureTenantDatabase($user);
        $this->switchToTenant($dbName);

        // Ensure we only sync columns that exist in the tenant table
        $syncData = [
            'id' => $restaurantData['id'],
            'user_id' => $restaurantData['user_id'],
            'name' => $restaurantData['name'],
            'slug' => $restaurantData['slug'],
            'logo' => $restaurantData['logo'] ?? null,
            'is_veg' => $restaurantData['is_veg'] ?? true,
            'is_nonveg' => $restaurantData['is_nonveg'] ?? true,
            'is_jain' => $restaurantData['is_jain'] ?? false,
            'upi_id' => $restaurantData['upi_id'] ?? null,
            'address' => $restaurantData['address'] ?? null,
            'takeaway_menu_card_id' => $restaurantData['takeaway_menu_card_id'] ?? null,
            'delivery_menu_card_id' => $restaurantData['delivery_menu_card_id'] ?? null,
            'tax_name' => $restaurantData['tax_name'] ?? null,
            'tax_registration_number' => $restaurantData['tax_registration_number'] ?? null,
            'fssai_number' => $restaurantData['fssai_number'] ?? null,
            'latitude' => $restaurantData['latitude'] ?? null,
            'longitude' => $restaurantData['longitude'] ?? null,
            'is_delivery' => $restaurantData['is_delivery'] ?? true,
            'is_takeaway' => $restaurantData['is_takeaway'] ?? true,
            'is_dinein' => $restaurantData['is_dinein'] ?? true,
            'bill_printer_ip' => $restaurantData['bill_printer_ip'] ?? null,
            'bill_printer_port' => $restaurantData['bill_printer_port'] ?? 9100,
            'created_at' => isset($restaurantData['created_at']) ? date('Y-m-d H:i:s', strtotime($restaurantData['created_at'])) : now(),
            'updated_at' => isset($restaurantData['updated_at']) ? date('Y-m-d H:i:s', strtotime($restaurantData['updated_at'])) : now(),
        ];

        DB::connection('tenant')->table('restaurants')->updateOrInsert(
            ['id' => $syncData['id']],
            $syncData
        );
    }

    /**
     * Delete a restaurant record from the tenant database.
     */
    public function deleteRestaurantFromTenant($user, $restaurantId)
    {
        $dbName = 'resto_'.str_replace('-', '_', $user->id);
        $this->switchToTenant($dbName);

        DB::connection('tenant')->table('restaurants')->where('id', $restaurantId)->delete();
    }
}
