<?php

namespace App\Http\Controllers\Api;

use App\Models\PaymentMethod;
use Illuminate\Routing\Controller;

class PaymentMethodController extends Controller
{
    /**
     * Get all active payment methods
     * GET /api/payment-methods
     *
     * Returns a list of available payment methods sorted by sort_order
     */
    public function index()
    {
        $paymentMethods = PaymentMethod::where('is_active', true)
            ->orderBy('sort_order', 'asc')
            ->orderBy('name', 'asc')
            ->select('id', 'name', 'code', 'description')
            ->get();

        return response()->json([
            'success' => true,
            'data' => $paymentMethods,
        ]);
    }
}
