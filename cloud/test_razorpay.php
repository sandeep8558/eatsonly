<?php

require 'vendor/autoload.php';
use Razorpay\Api\Api;

$key = 'rzp_test_mWA0jwDLrJtiN2';
$secret = 'OboobU6377T5w4eThleMsTdo';

try {
    $api = new Api($key, $secret);
    $order = $api->order->create([
        'receipt' => 'test_'.time(),
        'amount' => 100,
        'currency' => 'INR'
    ]);
    echo "SUCCESS: Order ID " . $order['id'] . "\n";
} catch (\Exception $e) {
    echo "FAILED: " . $e->getMessage() . "\n";
}
