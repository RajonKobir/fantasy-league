<?php

require_once __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';

$kernel = $app->make(\Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use App\Models\PaymentRequest;
use App\Models\User;

echo "=== Payment Request System Test ===\n\n";

// Check counts
$total = PaymentRequest::count();
$pending = PaymentRequest::where('status', 'pending')->count();
$approved = PaymentRequest::where('status', 'approved')->count();

echo "Total Payment Requests: $total\n";
echo "Pending: $pending\n";
echo "Approved: $approved\n\n";

// Show sample pending request
$pending_req = PaymentRequest::where('status', 'pending')->first();
if ($pending_req) {
    echo "Sample Pending Request:\n";
    echo "  ID: {$pending_req->id}\n";
    echo "  User: {$pending_req->user->name} ({$pending_req->user->email})\n";
    echo "  Amount: ৳{$pending_req->amount}\n";
    echo "  Method: {$pending_req->payment_method}\n";
    echo "  TRX ID: {$pending_req->transaction_number}\n";
    echo "  Status: {$pending_req->status}\n\n";
}

// Show sample approved request with approver
$approved_req = PaymentRequest::where('status', 'approved')->first();
if ($approved_req) {
    $approver_name = $approved_req->approvedByUser ? $approved_req->approvedByUser->name : 'N/A';
    echo "Sample Approved Request:\n";
    echo "  ID: {$approved_req->id}\n";
    echo "  User: {$approved_req->user->name}\n";
    echo "  Amount: ৳{$approved_req->amount}\n";
    echo "  Approved by: $approver_name\n";
    echo "  Approved at: {$approved_req->approved_at}\n\n";
}

// Check user wallets
echo "User Wallet Verification:\n";
$users = User::where('is_admin', 0)->limit(3)->get();
foreach ($users as $user) {
    $user_requests = PaymentRequest::where('user_id', $user->id)->count();
    $total_approved = PaymentRequest::where('user_id', $user->id)
        ->where('status', 'approved')
        ->sum('amount');
    echo "  {$user->name}: Wallet ৳{$user->wallet_balance}, Requests: $user_requests, Approved Amount: ৳$total_approved\n";
}

echo "\n=== Test Complete ===\n";
