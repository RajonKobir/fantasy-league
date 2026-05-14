<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class TransactionController extends Controller
{
    // GET /api/transactions - list transactions for authenticated user
    public function index(Request $request)
    {
        $user = $request->user();

        if (! $user) {
            return response()->json(['success' => 0, 'message' => 'Unauthenticated'], 401);
        }

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

        return response()->json(['success' => 1, 'message' => 'Transaction data get successfully', 'data' => ['transaction' => $transactions]]);
    }
}
