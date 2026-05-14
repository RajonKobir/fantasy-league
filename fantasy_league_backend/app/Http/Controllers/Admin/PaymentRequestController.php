<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\PaymentRequest;
use App\Models\PaymentMethod;
use App\Models\Transaction;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Inertia\Inertia;

class PaymentRequestController extends Controller
{
    /**
     * Show payment requests list
     */
    public function index(Request $request)
    {
        $status = $request->query('status', 'pending');
        $search = $request->query('q', '');
        $perPage = $request->query('per_page', 15);

        $query = PaymentRequest::query();

        if ($status && in_array($status, ['pending', 'approved', 'rejected'])) {
            $query->where('status', $status);
        }

        if ($search) {
            $query->where(function ($q) use ($search) {
                $q->whereHas('user', function ($subQ) use ($search) {
                    $subQ->where('name', 'like', "%{$search}%")
                        ->orWhere('email', 'like', "%{$search}%");
                })
                ->orWhere('transaction_number', 'like', "%{$search}%")
                ->orWhere('from_number', 'like', "%{$search}%");
            });
        }

        $paymentRequests = $query->with('user', 'approvedBy')
            ->latest()
            ->paginate($perPage);

        return Inertia::render('Admin/PaymentRequests/Index', [
            'paymentRequests' => $paymentRequests,
            'filters' => [
                'status' => $status,
                'q' => $search,
                'per_page' => $perPage,
            ],
        ]);
    }

    /**
     * Show payment request details
     */
    public function show(PaymentRequest $paymentRequest)
    {
        $paymentRequest->load('user', 'approvedBy');

        return Inertia::render('Admin/PaymentRequests/Show', [
            'paymentRequest' => $paymentRequest,
        ]);
    }

    /**
     * Show create payment request form
     */
    public function create()
    {
        $users = \App\Models\User::where('is_admin', 0)->get(['id', 'name', 'email']);
        $paymentMethods = PaymentMethod::where('is_active', true)
            ->orderBy('sort_order')
            ->orderBy('name')
            ->get(['id', 'name', 'code']);

        return Inertia::render('Admin/PaymentRequests/Create', [
            'users' => $users,
            'paymentMethods' => $paymentMethods,
        ]);
    }

    /**
     * Store a payment request created by admin
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'user_id' => 'required|exists:users,id',
            'payment_method' => 'required|in:bkash,rocket,nagod',
            'to_number' => 'required|regex:/^[0-9]{10,15}$/',
            'from_number' => 'required|regex:/^[0-9]{10,15}$/',
            'amount' => 'required|numeric|min:100|max:100000',
            'transaction_number' => 'required|string|unique:payment_requests,transaction_number',
        ]);

        $paymentRequest = PaymentRequest::create([
            ...$validated,
            'status' => 'pending',
        ]);

        return redirect()->route('admin.payment-requests.show', $paymentRequest->id)
            ->with('success', 'Payment request created successfully');
    }

    /**
     * Approve a payment request
     */
    public function approve(PaymentRequest $paymentRequest, Request $request)
    {
        // Validate
        $validated = $request->validate([
            'admin_notes' => 'nullable|string|max:500',
        ]);

        // Check if already approved or rejected
        if ($paymentRequest->status !== 'pending') {
            return back()->with('error', 'Only pending payment requests can be approved');
        }

        try {
            DB::beginTransaction();

            // Get user
            $user = $paymentRequest->user;

            // Add to wallet
            $user->wallet_balance += $paymentRequest->amount;
            $user->save();

            // Create transaction record
            Transaction::create([
                'user_id' => $user->id,
                'type' => 'credit',
                'amount' => $paymentRequest->amount,
                'remark' => "Payment request approved: {$paymentRequest->transaction_number}",
                'reference_type' => 'PaymentRequest',
                'reference_id' => $paymentRequest->id,
            ]);

            // Update payment request
            $paymentRequest->update([
                'status' => 'approved',
                'approved_by' => Auth::id(),
                'approved_at' => now(),
                'admin_notes' => $validated['admin_notes'] ?? null,
            ]);

            DB::commit();

            // Send notification to user (optional)
            // $user->notify(new PaymentRequestApprovedNotification($paymentRequest));

            return back()->with('success', 'Payment request approved successfully');

        } catch (\Exception $e) {
            DB::rollBack();
            return back()->with('error', 'Error approving payment request: ' . $e->getMessage());
        }
    }

    /**
     * Reject a payment request
     */
    public function reject(PaymentRequest $paymentRequest, Request $request)
    {
        // Validate
        $validated = $request->validate([
            'admin_notes' => 'required|string|max:500',
        ]);

        // Check if already approved or rejected
        if ($paymentRequest->status !== 'pending') {
            return back()->with('error', 'Only pending payment requests can be rejected');
        }

        try {
            // Update payment request
            $paymentRequest->update([
                'status' => 'rejected',
                'approved_by' => Auth::id(),
                'approved_at' => now(),
                'rejection_reason' => $validated['admin_notes'],
            ]);

            // Send notification to user (optional)
            // $user->notify(new PaymentRequestRejectedNotification($paymentRequest));

            return back()->with('success', 'Payment request rejected successfully');

        } catch (\Exception $e) {
            return back()->with('error', 'Error rejecting payment request: ' . $e->getMessage());
        }
    }
}
