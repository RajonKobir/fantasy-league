<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\PaymentMethod;
use Illuminate\Http\Request;
use Inertia\Inertia;

class PaymentMethodController extends Controller
{
    /**
     * Display payment methods list
     */
    public function index(Request $request)
    {
        $search = $request->query('q', '');
        $perPage = $request->query('per_page', 15);

        $query = PaymentMethod::query();

        if ($search) {
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                    ->orWhere('code', 'like', "%{$search}%")
                    ->orWhere('description', 'like', "%{$search}%");
            });
        }

        $paymentMethods = $query->orderBy('sort_order')
            ->orderBy('name')
            ->paginate($perPage);

        return Inertia::render('Admin/PaymentMethods/Index', [
            'paymentMethods' => $paymentMethods,
            'filters' => [
                'q' => $search,
                'per_page' => $perPage,
            ],
        ]);
    }

    /**
     * Show create payment method form
     */
    public function create()
    {
        return Inertia::render('Admin/PaymentMethods/Create');
    }

    /**
     * Store a payment method
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255|unique:payment_methods,name',
            'code' => 'required|string|max:255|unique:payment_methods,code',
            'description' => 'nullable|string',
            'is_active' => 'required|boolean',
            'sort_order' => 'nullable|integer',
        ]);

        $paymentMethod = PaymentMethod::create($validated);

        return redirect()->route('admin.payment-methods.index')
            ->with('success', 'Payment method created successfully');
    }

    /**
     * Show edit payment method form
     */
    public function edit(PaymentMethod $paymentMethod)
    {
        return Inertia::render('Admin/PaymentMethods/Edit', [
            'paymentMethod' => $paymentMethod,
        ]);
    }

    /**
     * Update a payment method
     */
    public function update(Request $request, PaymentMethod $paymentMethod)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255|unique:payment_methods,name,' . $paymentMethod->id,
            'code' => 'required|string|max:255|unique:payment_methods,code,' . $paymentMethod->id,
            'description' => 'nullable|string',
            'is_active' => 'required|boolean',
            'sort_order' => 'nullable|integer',
        ]);

        $paymentMethod->update($validated);

        return redirect()->route('admin.payment-methods.index')
            ->with('success', 'Payment method updated successfully');
    }

    /**
     * Delete a payment method
     */
    public function destroy(PaymentMethod $paymentMethod)
    {
        $paymentMethod->delete();

        return redirect()->route('admin.payment-methods.index')
            ->with('success', 'Payment method deleted successfully');
    }
}
