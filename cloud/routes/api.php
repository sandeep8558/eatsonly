<?php

use App\Http\Controllers\Api\AuthController;
use Illuminate\Support\Facades\Route;

// Public routes
Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);
Route::post('/forgot-password', [AuthController::class, 'forgotPassword']);
Route::post('/reset-password', [AuthController::class, 'resetPassword']);
Route::get('/payment/callback', [\App\Http\Controllers\Api\OrderController::class, 'paymentCallback'])->name('payment.callback');
Route::get('/reports/download', [\App\Http\Controllers\Api\ReportController::class, 'downloadReport']);
Route::post('/webhooks/zomato/order', [\App\Http\Controllers\Api\AggregatorWebhookController::class, 'handleZomatoOrder']);
Route::post('/webhooks/swiggy/order', [\App\Http\Controllers\Api\AggregatorWebhookController::class, 'handleSwiggyOrder']);

// Media Proxy (Public but scoped to storage)
Route::get('/media/{path}', function ($path) {
    $fullPath = storage_path('app/public/' . $path);
    if (!file_exists($fullPath)) abort(404);
    
    return response()->file($fullPath, [
        'Access-Control-Allow-Origin' => '*',
        'Access-Control-Allow-Methods' => 'GET',
        'Access-Control-Allow-Headers' => 'Content-Type, Authorization',
    ]);
})->where('path', '.*');

// Protected routes
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/me', [AuthController::class, 'me']);
    Route::post('/logout', [AuthController::class, 'logout']);
    
    // Profile Management
    Route::put('/profile', [\App\Http\Controllers\Api\ProfileController::class, 'update']);
    Route::put('/profile/password', [\App\Http\Controllers\Api\ProfileController::class, 'updatePassword']);
    Route::delete('/profile', [\App\Http\Controllers\Api\ProfileController::class, 'destroy']);

    // Routes requiring active subscription
    Route::middleware('subscription')->group(function () {
        Route::post('/upgrade', [AuthController::class, 'upgradeToRestaurantAdmin']);
        
        // --- ATTENDANCE ---
        Route::get('/attendance/status', [\App\Http\Controllers\Api\AttendanceController::class, 'getStatus']);
        Route::post('/attendance/clock-in', [\App\Http\Controllers\Api\AttendanceController::class, 'clockIn']);
        Route::post('/attendance/clock-out', [\App\Http\Controllers\Api\AttendanceController::class, 'clockOut']);
        Route::get('/attendance/history', [\App\Http\Controllers\Api\AttendanceController::class, 'getHistory']);
        
        // Restaurants CRUD
        Route::get('/restaurants', [\App\Http\Controllers\Api\RestaurantController::class, 'index']);
        Route::post('/restaurants', [\App\Http\Controllers\Api\RestaurantController::class, 'store']);
        Route::put('/restaurants/{id}', [\App\Http\Controllers\Api\RestaurantController::class, 'update']);
        Route::delete('/restaurants/{id}', [\App\Http\Controllers\Api\RestaurantController::class, 'destroy']);

        // Staff Management
        Route::get('/staff/search', [\App\Http\Controllers\Api\StaffController::class, 'search']);
        Route::get('/staff', [\App\Http\Controllers\Api\StaffController::class, 'index']);
        Route::post('/staff', [\App\Http\Controllers\Api\StaffController::class, 'store']);
        Route::put('/staff/{id}', [\App\Http\Controllers\Api\StaffController::class, 'update']);
        Route::delete('/staff/{id}', [\App\Http\Controllers\Api\StaffController::class, 'destroy']);

        Route::get('/roles', [\App\Http\Controllers\Api\RoleController::class, 'index']);

        // Menu Management
        Route::post('/menu/generate-description', [\App\Http\Controllers\Api\MenuController::class, 'generateDescription']);
        Route::get('/menu/suggestions/categories', [\App\Http\Controllers\Api\MenuController::class, 'searchMasterCategories']);
        Route::get('/menu/suggestions/items', [\App\Http\Controllers\Api\MenuController::class, 'searchMasterMenus']);
        // ... and all others below
        Route::get('/menu/cards', [\App\Http\Controllers\Api\MenuController::class, 'getMenuCards']);
        Route::post('/menu/cards', [\App\Http\Controllers\Api\MenuController::class, 'storeMenuCard']);
        Route::put('/menu/cards/{id}', [\App\Http\Controllers\Api\MenuController::class, 'updateMenuCard']);
        Route::delete('/menu/cards/{id}', [\App\Http\Controllers\Api\MenuController::class, 'deleteMenuCard']);
        Route::post('/menu/cards/clone', [\App\Http\Controllers\Api\MenuController::class, 'cloneMenuCard']);
        Route::post('/menu/sync-menus', [\App\Http\Controllers\Api\MenuController::class, 'syncRestaurantMenus']);
        Route::post('/menu/categories', [\App\Http\Controllers\Api\MenuController::class, 'storeMenuCategory']);
        Route::put('/menu/categories/{id}', [\App\Http\Controllers\Api\MenuController::class, 'updateMenuCategory']);
        Route::delete('/menu/categories/{id}', [\App\Http\Controllers\Api\MenuController::class, 'deleteMenuCategory']);
        Route::post('/menu/categories/reorder', [\App\Http\Controllers\Api\MenuController::class, 'reorderCategories']);
        Route::post('/menu/items/reorder', [\App\Http\Controllers\Api\MenuController::class, 'reorderItems']);
        Route::post('/menu/items', [\App\Http\Controllers\Api\MenuController::class, 'storeMenuItem']);
        Route::post('/menu/items/{id}', [\App\Http\Controllers\Api\MenuController::class, 'updateMenuItem']);
        Route::post('/menu/items/{id}/combo-groups', [\App\Http\Controllers\Api\MenuController::class, 'saveComboGroups']);
        Route::delete('/menu/items/{id}', [\App\Http\Controllers\Api\MenuController::class, 'deleteMenuItem']);

        // Table & Floor
        Route::get('/floors', [\App\Http\Controllers\Api\TableController::class, 'getFloors']);
        Route::post('/floors', [\App\Http\Controllers\Api\TableController::class, 'storeFloor']);
        Route::put('/floors/{id}', [\App\Http\Controllers\Api\TableController::class, 'updateFloor']);
        Route::delete('/floors/{id}', [\App\Http\Controllers\Api\TableController::class, 'deleteFloor']);
        Route::post('/tables', [\App\Http\Controllers\Api\TableController::class, 'storeTable']);
        Route::put('/tables/{id}', [\App\Http\Controllers\Api\TableController::class, 'updateTable']);
        Route::delete('/tables/{id}', [\App\Http\Controllers\Api\TableController::class, 'deleteTable']);
        Route::post('/tables/layout', [\App\Http\Controllers\Api\TableController::class, 'updateLayout']);

        // POS & Orders
        Route::get('/orders', [\App\Http\Controllers\Api\OrderController::class, 'index']);
        Route::get('/orders/stats', [\App\Http\Controllers\Api\OrderController::class, 'getDashboardStats']);
        Route::get('/orders/active', [\App\Http\Controllers\Api\OrderController::class, 'getActiveOrders']);
        Route::post('/orders/kot', [\App\Http\Controllers\Api\OrderController::class, 'sendKOT']);
        Route::post('/orders/remove-item', [\App\Http\Controllers\Api\OrderController::class, 'removeItem']);
        Route::post('/orders/{id}/bill', [\App\Http\Controllers\Api\OrderController::class, 'generateBill']);
        Route::post('/orders/{id}/reopen', [\App\Http\Controllers\Api\OrderController::class, 'reopen']);
        Route::delete('/orders/{id}', [\App\Http\Controllers\Api\OrderController::class, 'destroy']);
        Route::post('/orders/transfer', [\App\Http\Controllers\Api\OrderController::class, 'transferTable']);
        Route::post('/orders/merge', [\App\Http\Controllers\Api\OrderController::class, 'mergeTable']);
        Route::post('/orders/{id}/razorpay-initiate', [\App\Http\Controllers\Api\OrderController::class, 'initiateRazorpayPayment']);
        Route::get('/orders/delivery-partners', [\App\Http\Controllers\Api\OrderController::class, 'getDeliveryPartners']);
        Route::post('/orders/{id}/assign-delivery', [\App\Http\Controllers\Api\OrderController::class, 'assignDeliveryPartner']);

        Route::get('/kots', [\App\Http\Controllers\Api\KOTController::class, 'index']);
        Route::post('/kots/{id}/status', [\App\Http\Controllers\Api\KOTController::class, 'updateStatus']);

        Route::get('/kds-stations', [\App\Http\Controllers\Api\KDSStationController::class, 'index']);
        Route::post('/kds-stations', [\App\Http\Controllers\Api\KDSStationController::class, 'store']);
        Route::put('/kds-stations/{id}', [\App\Http\Controllers\Api\KDSStationController::class, 'update']);
        Route::delete('/kds-stations/{id}', [\App\Http\Controllers\Api\KDSStationController::class, 'destroy']);

        Route::get('/settings', [\App\Http\Controllers\Api\SettingController::class, 'index']);
        Route::post('/settings', [\App\Http\Controllers\Api\SettingController::class, 'update']);

        Route::get('/tax-groups', [\App\Http\Controllers\Api\TaxGroupController::class, 'index']);
        Route::post('/tax-groups', [\App\Http\Controllers\Api\TaxGroupController::class, 'store']);
        Route::get('/tax-groups/{id}', [\App\Http\Controllers\Api\TaxGroupController::class, 'show']);
        Route::put('/tax-groups/{id}', [\App\Http\Controllers\Api\TaxGroupController::class, 'update']);
        Route::delete('/tax-groups/{id}', [\App\Http\Controllers\Api\TaxGroupController::class, 'destroy']);

        Route::get('/reports/tips', [\App\Http\Controllers\Api\ReportController::class, 'getTipReport']);
        Route::get('/reports/sales', [\App\Http\Controllers\Api\ReportController::class, 'getSalesReport']);
        Route::get('/reports/leakage', [\App\Http\Controllers\Api\ReportController::class, 'getLeakageReport']);
        Route::get('/reports/menu-engineering', [\App\Http\Controllers\Api\ReportController::class, 'getMenuEngineeringReport']);

        Route::get('/delivery/orders/available', [\App\Http\Controllers\Api\DeliveryController::class, 'availableDeliveries']);
        Route::get('/delivery/orders/active', [\App\Http\Controllers\Api\DeliveryController::class, 'activeDeliveries']);
        Route::get('/delivery/orders/delivered', [\App\Http\Controllers\Api\DeliveryController::class, 'deliveredDeliveries']);
        Route::post('/delivery/orders/{id}/accept', [\App\Http\Controllers\Api\DeliveryController::class, 'acceptDelivery']);
        Route::post('/delivery/orders/{id}/status', [\App\Http\Controllers\Api\DeliveryController::class, 'updateStatus']);
        Route::post('/delivery/orders/{id}/location', [\App\Http\Controllers\Api\DeliveryController::class, 'updateLocation']);
        Route::get('/delivery/summary', [\App\Http\Controllers\Api\DeliveryController::class, 'earningsSummary']);

        Route::get('/customers', [\App\Http\Controllers\Api\CustomerController::class, 'index']);
        Route::post('/customers', [\App\Http\Controllers\Api\CustomerController::class, 'store']);

        Route::get('/addresses', [\App\Http\Controllers\Api\AddressController::class, 'index']);
        Route::post('/addresses', [\App\Http\Controllers\Api\AddressController::class, 'store']);
        Route::put('/addresses/{address}', [\App\Http\Controllers\Api\AddressController::class, 'update']);
        Route::delete('/addresses/{address}', [\App\Http\Controllers\Api\AddressController::class, 'destroy']);
        Route::post('/addresses/{address}/default', [\App\Http\Controllers\Api\AddressController::class, 'setDefault']);

        Route::get('/inventory', [\App\Http\Controllers\Api\InventoryController::class, 'index']);
        Route::post('/inventory', [\App\Http\Controllers\Api\InventoryController::class, 'store']);
        Route::put('/inventory/{id}', [\App\Http\Controllers\Api\InventoryController::class, 'update']);
        Route::delete('/inventory/{id}', [\App\Http\Controllers\Api\InventoryController::class, 'destroy']);

        Route::get('/inventory-categories', [\App\Http\Controllers\Api\InventoryCategoryController::class, 'index']);
        Route::post('/inventory-categories', [\App\Http\Controllers\Api\InventoryCategoryController::class, 'store']);
        Route::put('/inventory-categories/{id}', [\App\Http\Controllers\Api\InventoryCategoryController::class, 'update']);
        Route::delete('/inventory-categories/{id}', [\App\Http\Controllers\Api\InventoryCategoryController::class, 'destroy']);

        Route::get('/suppliers', [\App\Http\Controllers\Api\SupplierController::class, 'index']);
        Route::post('/suppliers', [\App\Http\Controllers\Api\SupplierController::class, 'store']);
        Route::put('/suppliers/{id}', [\App\Http\Controllers\Api\SupplierController::class, 'update']);
        Route::delete('/suppliers/{id}', [\App\Http\Controllers\Api\SupplierController::class, 'destroy']);

        Route::get('/purchases', [\App\Http\Controllers\Api\PurchaseController::class, 'index']);
        Route::post('/purchases', [\App\Http\Controllers\Api\PurchaseController::class, 'store']);
        Route::put('/purchases/{id}', [\App\Http\Controllers\Api\PurchaseController::class, 'update']);
        Route::delete('/purchases/{id}', [\App\Http\Controllers\Api\PurchaseController::class, 'destroy']);

        Route::get('/recipes', [\App\Http\Controllers\Api\RecipeController::class, 'index']);
        Route::post('/recipes', [\App\Http\Controllers\Api\RecipeController::class, 'store']);

        Route::get('/issuances', [\App\Http\Controllers\Api\MaterialIssuanceController::class, 'index']);
        Route::post('/issuances', [\App\Http\Controllers\Api\MaterialIssuanceController::class, 'store']);

        Route::get('/wastage', [\App\Http\Controllers\Api\WastageController::class, 'index']);
        Route::post('/wastage', [\App\Http\Controllers\Api\WastageController::class, 'store']);

        Route::get('/stock-ledger', [\App\Http\Controllers\Api\StockLedgerController::class, 'index']);

        Route::get('/stock-audits', [\App\Http\Controllers\Api\StockAuditController::class, 'index']);
        Route::post('/stock-audits', [\App\Http\Controllers\Api\StockAuditController::class, 'store']);

        Route::get('/integrations', [\App\Http\Controllers\Api\IntegrationController::class, 'index']);
        Route::post('/integrations/credentials', [\App\Http\Controllers\Api\IntegrationController::class, 'saveCredentials']);
        Route::get('/integrations/menu', [\App\Http\Controllers\Api\IntegrationController::class, 'getMenuMapping']);
        Route::post('/integrations/map-item', [\App\Http\Controllers\Api\IntegrationController::class, 'mapItem']);
    });
});
