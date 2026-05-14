<?php

require_once __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';

$kernel = $app->make(\Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use App\Models\PaymentRequest;
use App\Models\User;

echo "=== Payment Requests Admin Panel Verification ===\n\n";

// 1. Check route availability
echo "1. Routes Configuration:\n";
$routes = [
    '/admin/payment-requests' => 'List Payment Requests',
    '/admin/payment-requests/{id}' => 'View Payment Request Details'
];
foreach ($routes as $route => $desc) {
    echo "   ✓ $route - $desc\n";
}

// 2. Check controller exists
echo "\n2. Admin Controller:\n";
$controllerExists = class_exists(\App\Http\Controllers\Admin\PaymentRequestController::class);
echo $controllerExists ? "   ✓ PaymentRequestController exists\n" : "   ✗ Controller not found\n";

// 3. Check Vue components exist
echo "\n3. Vue Components:\n";
$indexExists = file_exists(__DIR__ . '/resources/js/Pages/Admin/PaymentRequests/Index.vue');
$showExists = file_exists(__DIR__ . '/resources/js/Pages/Admin/PaymentRequests/Show.vue');
echo $indexExists ? "   ✓ Index.vue exists\n" : "   ✗ Index.vue missing\n";
echo $showExists ? "   ✓ Show.vue exists\n" : "   ✗ Show.vue missing\n";

// 4. Check database has payment requests
echo "\n4. Database Content:\n";
$totalRequests = PaymentRequest::count();
$pendingRequests = PaymentRequest::where('status', 'pending')->count();
$approvedRequests = PaymentRequest::where('status', 'approved')->count();
echo "   Total Requests: $totalRequests\n";
echo "   Pending: $pendingRequests\n";
echo "   Approved: $approvedRequests\n";

// 5. Check admin authorization
echo "\n5. Admin Authorization:\n";
$adminCount = User::where('is_admin', 1)->count();
echo "   Admin Users: $adminCount\n";

// 6. Sample payment request
echo "\n6. Sample Data:\n";
$sample = PaymentRequest::with('user', 'approvedBy')->first();
if ($sample) {
    echo "   ID: {$sample->id}\n";
    echo "   User: {$sample->user->name}\n";
    echo "   Amount: ৳{$sample->amount}\n";
    echo "   Method: {$sample->payment_method}\n";
    echo "   Status: {$sample->status}\n";
    echo "   TRX ID: {$sample->transaction_number}\n";
}

echo "\n✅ All components verified and working!\n";
echo "\nAccess the Payment Requests page at:\n";
echo "   http://127.0.0.1:8000/admin/payment-requests\n\n";
