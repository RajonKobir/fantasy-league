<?php

namespace App\Http\Controllers\Api;

use App\Models\PaymentRequest;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Routing\Controller;
use Illuminate\Support\Facades\DB;

class PaymentRequestController extends Controller
{
    /**
     * Get user's payment requests (user endpoint)
     */
    public function userIndex(Request $request)
    {
        $requests = $request->user()->paymentRequests()
            ->latest()
            ->paginate(15);

        return response()->json(['success' => true, 'data' => $requests]);
    }

    /**
     * Submit a new payment request
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'payment_method' => 'required|in:bkash,rocket,nagod',
            'to_number' => 'required|string|regex:/^[0-9]{10,15}$/',
            'from_number' => 'required|string|regex:/^[0-9]{10,15}$/',
            'amount' => 'required|numeric|min:100|max:100000',
            'transaction_number' => 'required|string|unique:payment_requests,transaction_number',
        ]);

        $paymentRequest = $request->user()->paymentRequests()->create($validated);

        return response()->json([
            'success' => true,
            'message' => 'Payment request submitted successfully',
            'data' => $paymentRequest,
        ], 201);
    }

    /**
     * Get payment request details
     */
    public function show(PaymentRequest $paymentRequest, Request $request)
    {
        // User can only view their own requests
        if ($paymentRequest->user_id !== $request->user()->id && !$request->user()->is_admin) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        return response()->json($paymentRequest->load('user', 'approvedBy'));
    }

    /**
     * Admin endpoints
     */

    /**
     * Get all payment requests (admin only)
     */
    public function adminIndex(Request $request)
    {
        $this->authorize('isAdmin', User::class);

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

        $requests = $query->with('user', 'approvedBy')
            ->latest()
            ->paginate($perPage);

        return response()->json(['success' => true, 'data' => $requests]);
    }

    /**
     * Approve a payment request
     */
    public function approve(PaymentRequest $paymentRequest, Request $request)
    {
        $this->authorize('isAdmin', User::class);

        if ($paymentRequest->status !== 'pending') {
            return response()->json([
                'message' => "Cannot approve a {$paymentRequest->status} request",
            ], 422);
        }

        $validated = $request->validate([
            'admin_notes' => 'nullable|string|max:500',
        ]);

        DB::transaction(function () use ($paymentRequest, $request, $validated) {
            // Update payment request status
            $paymentRequest->update([
                'status' => 'approved',
                'approved_at' => now(),
                'approved_by' => $request->user()->id,
                'admin_notes' => $validated['admin_notes'] ?? null,
            ]);

            // Add amount to user's wallet
            $user = $paymentRequest->user;
            $user->increment('wallet_balance', $paymentRequest->amount);

            // Log the transaction
            \App\Models\Transaction::create([
                'user_id' => $user->id,
                'type' => 'credit',
                'amount' => $paymentRequest->amount,
                'description' => "Payment via {$paymentRequest->payment_method} (TrxID: {$paymentRequest->transaction_number})",
                'payment_method' => $paymentRequest->payment_method,
            ]);
        });

        return response()->json([
            'success' => true,
            'message' => 'Payment request approved and wallet updated',
            'data' => $paymentRequest->refresh(),
        ]);
    }

    /**
     * Reject a payment request
     */
    public function reject(PaymentRequest $paymentRequest, Request $request)
    {
        $this->authorize('isAdmin', User::class);

        if ($paymentRequest->status !== 'pending') {
            return response()->json([
                'message' => "Cannot reject a {$paymentRequest->status} request",
            ], 422);
        }

        $validated = $request->validate([
            'rejection_reason' => 'required|string|max:500',
        ]);

        $paymentRequest->update([
            'status' => 'rejected',
            'rejection_reason' => $validated['rejection_reason'],
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Payment request rejected',
            'data' => $paymentRequest,
        ]);
    }
}
