<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\CancelRequest;
use App\Models\FantasyTeam;
use App\Models\Tournament;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Inertia\Inertia;

class CancelRequestController extends Controller
{
    /**
     * Display a listing of cancel requests with filtering.
     * GET /admin/cancel-requests
     */
    public function index(Request $request)
    {
        $query = CancelRequest::with(['fantasyTeam', 'user', 'tournament', 'approvedBy'])
            ->orderBy('created_at', 'desc');

        // Filter by status
        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }

        // Filter by user
        if ($request->filled('user_id')) {
            $query->where('user_id', $request->user_id);
        }

        // Filter by tournament
        if ($request->filled('tournament_id')) {
            $query->where('tournament_id', $request->tournament_id);
        }

        // Search by team name or user name
        if ($request->filled('search')) {
            $search = '%' . $request->search . '%';
            $query->whereHas('fantasyTeam', function ($q) use ($search) {
                $q->where('name', 'like', $search);
            })->orWhereHas('user', function ($q) use ($search) {
                $q->where('name', 'like', $search)->orWhere('email', 'like', $search);
            });
        }

        $cancelRequests = $query->paginate(15);

        // Get filter options
        $statuses = ['pending', 'approved', 'rejected'];
        $users = User::orderBy('name')->get(['id', 'name', 'email']);
        $tournaments = Tournament::orderBy('name')->get(['id', 'name']);

        return Inertia::render('Admin/CancelRequests/Index', [
            'cancelRequests' => $cancelRequests,
            'statuses' => $statuses,
            'users' => $users,
            'tournaments' => $tournaments,
            'filters' => [
                'status' => $request->status,
                'user_id' => $request->user_id,
                'tournament_id' => $request->tournament_id,
                'search' => $request->search,
            ],
        ]);
    }

    /**
     * Show the form for creating a new cancel request.
     * GET /admin/cancel-requests/create
     */
    public function create()
    {
        $fantasyTeams = FantasyTeam::where('status', '!=', 'canceled')
            ->with(['user', 'tournament'])
            ->orderBy('created_at', 'desc')
            ->get();

        return Inertia::render('Admin/CancelRequests/Create', [
            'fantasyTeams' => $fantasyTeams,
        ]);
    }

    /**
     * Store a newly created cancel request in storage.
     * POST /admin/cancel-requests
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'fantasy_team_id' => 'required|exists:fantasy_teams,id',
        ]);

        $fantasyTeam = FantasyTeam::with(['tournament'])->findOrFail($validated['fantasy_team_id']);

        // Check if team is already canceled
        if ($fantasyTeam->status === 'canceled') {
            return back()->withErrors(['fantasy_team_id' => 'This team is already canceled.']);
        }

        // Check for existing pending request
        $existingRequest = CancelRequest::where('fantasy_team_id', $fantasyTeam->id)
            ->where('status', 'pending')
            ->first();

        if ($existingRequest) {
            return back()->withErrors(['fantasy_team_id' => 'A pending cancel request already exists for this team.']);
        }

        $refundPercentage = $fantasyTeam->tournament->refund_percentage ?? 100.0;

        CancelRequest::create([
            'fantasy_team_id' => $fantasyTeam->id,
            'user_id' => $fantasyTeam->user_id,
            'tournament_id' => $fantasyTeam->tournament_id,
            'status' => 'pending',
            'refund_percentage_at_request' => $refundPercentage,
            'refund_amount' => 0.00,
            'admin_notes' => null,
            'approved_by' => null,
            'approved_at' => null,
        ]);

        return redirect()->route('admin.cancel-requests.index')
            ->with('success', 'Cancel request created successfully.');
    }

    /**
     * Show the details of a cancel request.
     * GET /admin/cancel-requests/{cancelRequest}
     */
    public function show(CancelRequest $cancelRequest)
    {
        $cancelRequest->load(['fantasyTeam.user', 'user', 'tournament', 'approvedBy']);

        return Inertia::render('Admin/CancelRequests/Show', [
            'cancelRequest' => $cancelRequest,
        ]);
    }

    /**
     * Approve a cancel request (issue refund).
     * POST /admin/cancel-requests/{cancelRequest}/approve
     */
    public function approve(Request $request, CancelRequest $cancelRequest)
    {
        if ($cancelRequest->status !== 'pending') {
            return back()->withErrors(['status' => 'Only pending requests can be approved.']);
        }

        $cancelRequest->load(['fantasyTeam', 'user', 'tournament']);

        DB::transaction(function () use ($cancelRequest, $request) {
            $fantasyTeam = $cancelRequest->fantasyTeam;
            $user = $cancelRequest->user;
            $entryFee = $fantasyTeam->tournament->entry_fee;
            $refundPercentage = $cancelRequest->refund_percentage_at_request;
            $refundAmount = $entryFee * ($refundPercentage / 100);

            // Update user wallet
            $user->update([
                'wallet_balance' => $user->wallet_balance + $refundAmount,
            ]);

            // Create transaction record
            \App\Models\Transaction::create([
                'user_id' => $user->id,
                'type' => 'refund',
                'amount' => $refundAmount,
                'description' => "Refund for canceled fantasy team: {$fantasyTeam->name}",
            ]);

            // Update cancel request
            $cancelRequest->update([
                'status' => 'approved',
                'approved_by' => Auth::id(),
                'approved_at' => now(),
                'refund_amount' => $refundAmount,
            ]);

            // Mark team as canceled
            $fantasyTeam->update(['status' => 'canceled']);
        });

        return redirect()->route('admin.cancel-requests.show', $cancelRequest)
            ->with('success', 'Cancel request approved and refund issued successfully.');
    }

    /**
     * Reject a cancel request.
     * POST /admin/cancel-requests/{cancelRequest}/reject
     */
    public function reject(Request $request, CancelRequest $cancelRequest)
    {
        $validated = $request->validate([
            'admin_notes' => 'nullable|string|max:500',
        ]);

        if ($cancelRequest->status !== 'pending') {
            return back()->withErrors(['status' => 'Only pending requests can be rejected.']);
        }

        $cancelRequest->update([
            'status' => 'rejected',
            'admin_notes' => $validated['admin_notes'],
            'approved_by' => Auth::id(),
            'approved_at' => now(),
        ]);

        return redirect()->route('admin.cancel-requests.show', $cancelRequest)
            ->with('success', 'Cancel request rejected successfully.');
    }

    /**
     * Delete a cancel request.
     * DELETE /admin/cancel-requests/{cancelRequest}
     */
    public function destroy(CancelRequest $cancelRequest)
    {
        $cancelRequest->delete();

        return redirect()->route('admin.cancel-requests.index')
            ->with('success', 'Cancel request deleted successfully.');
    }
}
