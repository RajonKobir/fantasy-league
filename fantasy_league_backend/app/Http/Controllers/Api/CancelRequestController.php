<?php

namespace App\Http\Controllers\Api;

use App\Models\CancelRequest;
use App\Models\FantasyTeam;
use App\Models\Transaction;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Routing\Controller;
use Illuminate\Support\Facades\DB;

class CancelRequestController extends Controller
{
    // User: list their cancel requests
    public function userIndex(Request $request)
    {
        $requests = $request->user()->cancelRequests()->latest()->paginate(15);
        return response()->json($requests);
    }

    // User: submit cancel request for a fantasy team
    public function store(Request $request)
    {
        $validated = $request->validate([
            'fantasy_team_id' => 'required|exists:fantasy_teams,id',
            'reason' => 'nullable|string|max:500',
        ]);

        $team = FantasyTeam::findOrFail($validated['fantasy_team_id']);

        // user must own the team
        if ($team->user_id !== $request->user()->id) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        // Load tournament relation for checks
        $team->load('tournament');

        // Only allow cancel requests for teams that have been approved by admin
        if ($team->status !== 'approved') {
            return response()->json([
                'success' => false,
                'message' => 'Cancel requests are allowed only for admin-approved fantasy teams.'
            ], 422);
        }

        // Only allow cancel requests while tournament is running or active
        if (! $team->tournament || !in_array(($team->tournament->status ?? ''), ['running', 'active'])) {
            return response()->json([
                'success' => false,
                'message' => 'Cancel requests are only allowed for teams in running or active tournaments.'
            ], 422);
        }

        // Do not allow cancel request for already canceled team
        if ($team->status === 'canceled') {
            return response()->json([
                'success' => false,
                'message' => 'This fantasy team has already been canceled.'
            ], 422);
        }

        // Prevent duplicate pending cancel requests for same team
        if (CancelRequest::where('fantasy_team_id', $team->id)->where('status', 'pending')->exists()) {
            return response()->json([
                'success' => false,
                'message' => 'You have already sent a cancel request for this fantasy team.'
            ], 422);
        }

        // create cancel request
        $refundPercentage = $team->tournament->refund_percentage ?? 100.00;

        $cancelRequest = CancelRequest::create([
            'fantasy_team_id' => $team->id,
            'user_id' => $request->user()->id,
            'tournament_id' => $team->tournament_id,
            'refund_percentage_at_request' => $refundPercentage,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Cancel request submitted',
            'data' => $cancelRequest,
        ], 201);
    }

    // Admin: list cancel requests
    public function adminIndex(Request $request)
    {
        $this->authorize('isAdmin', User::class);

        $query = CancelRequest::query()->with('user', 'fantasyTeam', 'tournament');
        $status = $request->query('status', 'pending');
        if (in_array($status, ['pending', 'approved', 'rejected'])) {
            $query->where('status', $status);
        }

        $requests = $query->latest()->paginate($request->query('per_page', 15));
        return response()->json($requests);
    }

    // Admin: approve cancel request -> refund and cancel team
    public function approve(CancelRequest $cancelRequest, Request $request)
    {
        $this->authorize('isAdmin', User::class);

        if ($cancelRequest->status !== 'pending') {
            return response()->json(['message' => 'Cannot approve non-pending request'], 422);
        }

        DB::transaction(function () use ($cancelRequest, $request) {
            $team = $cancelRequest->fantasyTeam()->with('tournament', 'user')->first();
            if (! $team) {
                throw new \Exception('Fantasy team not found');
            }

            $tournament = $team->tournament;
            $user = $team->user;

            $percentage = $cancelRequest->refund_percentage_at_request ?? ($tournament->refund_percentage ?? 100.00);
            $refundAmount = round(($tournament->entry_fee * $percentage) / 100, 2);

            // Mark cancel request approved
            $cancelRequest->update([
                'status' => 'approved',
                'approved_at' => now(),
                'approved_by' => $request->user()->id,
                'refund_amount' => $refundAmount,
            ]);

            // Credit user's wallet
            $user->increment('wallet_balance', $refundAmount);

            // Log transaction
            Transaction::create([
                'user_id' => $user->id,
                'type' => 'credit',
                'amount' => $refundAmount,
                'description' => "Refund for canceled fantasy team (team_id: {$team->id})",
            ]);

            // Mark fantasy team canceled
            $team->update(['status' => 'canceled']);
        });

        return response()->json(['success' => true, 'message' => 'Cancel request approved and refund issued', 'data' => $cancelRequest->refresh()]);
    }

    // Admin: reject cancel request
    public function reject(CancelRequest $cancelRequest, Request $request)
    {
        $this->authorize('isAdmin', User::class);

        if ($cancelRequest->status !== 'pending') {
            return response()->json(['message' => 'Cannot reject non-pending request'], 422);
        }

        $validated = $request->validate(['rejection_reason' => 'required|string|max:500']);

        $cancelRequest->update([
            'status' => 'rejected',
            'admin_notes' => $validated['rejection_reason'],
        ]);

        return response()->json(['success' => true, 'message' => 'Cancel request rejected', 'data' => $cancelRequest]);
    }
}
