<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Transaction;
use App\Models\User;
use App\Models\AdminWalletLog;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class WalletController extends Controller
{
    // GET /api/wallet - show authenticated user's wallet balance and transactions
    public function show(Request $request)
    {
        $user = $request->user();
        if (! $user) {
            return response()->json(['success' => 0, 'message' => 'Unauthenticated'], 401);
        }

        // Refresh user from DB to ensure latest wallet balance is returned (useful after recent admin credits)
        $user = $user->fresh();

        $transactions = $user->transactions()->orderByDesc('time')->get()->map(function ($t) {
            return [
                'transaction_id' => $t->transaction_id,
                'type' => $t->type,
                'remark' => $t->remark,
                'amount' => (string) $t->amount,
                'team_name' => $t->team_name,
                'status_request' => $t->status_request,
                'status_process' => $t->status_process,
                'status_credit' => $t->status_credit,
                'time' => $t->time ? $t->time->format('d/m/Y,h:i:s A') : null,
            ];
        })->toArray();

        return response()->json(['success' => 1, 'message' => 'Wallet data fetched', 'data' => [
            'wallet_balance' => (string) number_format($user->wallet_balance ?? 0, 2, '.', ''),
            'transactions' => $transactions,
        ]]);
    }

    // POST /admin/users/{user}/wallet/credit - admin credits a user's wallet
    public function credit(Request $request, User $user)
    {
        $auth = $request->user();
        if (! $auth || ! $auth->is_admin) {
            return response()->json(['success' => 0, 'message' => 'Forbidden'], 403);
        }

        $validated = $request->validate([
            'amount' => 'required|numeric|min:0.01',
            'remark' => 'nullable|string',
        ]);

        $amount = (float) $validated['amount'];

        // Update wallet balance
        $previous = (float) ($user->wallet_balance ?? 0);
        $user->wallet_balance = $previous + $amount;
        $user->save();

        // Create transaction record
        $transaction = Transaction::create([
            'user_id' => $user->id,
            'transaction_id' => 'ADM'.strtoupper(Str::random(8)),
            'type' => 'RECEIVE',
            'remark' => $validated['remark'] ?? 'Manual credit by admin',
            'amount' => $amount,
            'team_name' => null,
            'status_process' => '1',
            'status_credit' => '1',
            'time' => now(),
        ]);

        // Audit log
        AdminWalletLog::create([
            'admin_id' => $auth->id,
            'user_id' => $user->id,
            'action' => 'credit',
            'amount' => $amount,
            'previous_balance' => $previous,
            'new_balance' => (float) $user->wallet_balance,
            'remark' => $validated['remark'] ?? 'Manual credit by admin',
        ]);

        return response()->json(['success' => 1, 'message' => 'User wallet credited successfully', 'data' => [
            'user_id' => $user->id,
            'amount' => (string) number_format($amount, 2, '.', ''),
            'wallet_balance' => (string) number_format($user->wallet_balance, 2, '.', ''),
        ]]);
    }

    // POST /admin/users/{user}/wallet/adjust - admin can credit, debit, or set a user's wallet
    public function adjust(Request $request, User $user)
    {
        $auth = $request->user();
        if (! $auth || ! $auth->is_admin) {
            return response()->json(['success' => 0, 'message' => 'Forbidden'], 403);
        }

        $validated = $request->validate([
            'action' => 'required|in:credit,debit,set',
            'amount' => 'required|numeric|min:0',
            'remark' => 'nullable|string',
            'force' => 'nullable|boolean',
        ]);

        $action = $validated['action'];
        $amount = (float) $validated['amount'];
        $force = ! empty($validated['force']);

        $old = (float) ($user->wallet_balance ?? 0);

        if ($action === 'debit') {
            if (!$force && $old < $amount) {
                return response()->json(['success' => 0, 'message' => 'Insufficient balance'], 422);
            }
            $user->wallet_balance = $old - $amount;
            $tranType = 'ADMIN_DEBIT';
            $tranAmount = -1 * $amount;
        } elseif ($action === 'credit') {
            $user->wallet_balance = $old + $amount;
            $tranType = 'RECEIVE';
            $tranAmount = $amount;
        } else { // set
            $user->wallet_balance = $amount;
            $tranType = 'ADMIN_ADJUST';
            $tranAmount = $amount - $old; // can be negative
        }

        $previous = (float) ($user->getOriginal('wallet_balance') ?? 0);
        $user->save();

        Transaction::create([
            'user_id' => $user->id,
            'transaction_id' => 'ADM'.strtoupper(Str::random(8)),
            'type' => $tranType,
            'remark' => $validated['remark'] ?? ("Admin {$action} wallet"),
            'amount' => $tranAmount,
            'team_name' => null,
            'status_process' => '1',
            'status_credit' => '1',
            'time' => now(),
        ]);

        // Audit log
        AdminWalletLog::create([
            'admin_id' => $auth->id,
            'user_id' => $user->id,
            'action' => $action,
            'amount' => $tranAmount,
            'previous_balance' => $previous,
            'new_balance' => (float) $user->wallet_balance,
            'remark' => $validated['remark'] ?? ("Admin {$action} wallet"),
        ]);

        return response()->json(['success' => 1, 'message' => 'Wallet adjusted', 'data' => [
            'user_id' => $user->id,
            'amount' => (string) number_format($tranAmount, 2, '.', ''),
            'wallet_balance' => (string) number_format($user->wallet_balance, 2, '.', ''),
        ]]);
    }

    // GET /admin/users/{user}/wallet/logs - list admin wallet logs for a user (admin only)
    public function logs(Request $request, User $user)
    {
        $auth = $request->user();
        if (! $auth || ! $auth->is_admin) {
            return response()->json(['success' => 0, 'message' => 'Forbidden'], 403);
        }

        $perPage = (int) $request->query('per_page', 20);
        $q = $request->query('q');

        $query = AdminWalletLog::where('user_id', $user->id)->with('admin');

        if ($q) {
            $query->where(function ($sub) use ($q) {
                $sub->where('action', 'like', "%{$q}%")
                    ->orWhere('remark', 'like', "%{$q}%")
                    ->orWhereHas('admin', function ($aq) use ($q) {
                        $aq->where('name', 'like', "%{$q}%");
                    });
            });
        }

        $logs = $query->orderByDesc('created_at')->paginate($perPage);

        // Map items and include pagination metadata
        $items = collect($logs->items())->map(function ($log) {
            return [
                'id' => $log->id,
                'admin' => [
                    'id' => $log->admin->id,
                    'name' => $log->admin->name,
                ],
                'action' => $log->action,
                'amount' => (string) number_format($log->amount, 2, '.', ''),
                'previous_balance' => (string) number_format($log->previous_balance, 2, '.', ''),
                'new_balance' => (string) number_format($log->new_balance, 2, '.', ''),
                'remark' => $log->remark,
                'created_at' => $log->created_at->toDateTimeString(),
            ];
        })->values()->all();

        $meta = [
            'current_page' => $logs->currentPage(),
            'last_page' => $logs->lastPage(),
            'per_page' => $logs->perPage(),
            'total' => $logs->total(),
        ];

        return response()->json(['success' => 1, 'message' => 'Logs fetched', 'data' => $items, 'meta' => $meta]);
    }
}

