<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    // GET /api/notifications - return paginated notification list for the authenticated user
    public function index(Request $request)
    {
        $user = $request->user();

        if (! $user) {
            return response()->json(['success' => 0, 'message' => 'Unauthenticated'], 401);
        }

        $perPage = max(10, (int) $request->query('per_page', 30));

        $notifications = $user->notifications()
            ->orderByDesc('created_at')
            ->paginate($perPage);

        // Transform the collection
        $notifications->getCollection()->transform(function ($n) {
            return [
                'type' => $n->type,
                'notification_detail' => $n->notification_detail,
                'date' => $n->created_at ? $n->created_at->format('d/m/Y') : null,
                'read_at' => $n->read_at,
            ];
        });

        return response()->json([
            'success' => 1,
            'message' => 'Notification data fetched successfully',
            'data' => $notifications->items(),
            'current_page' => $notifications->currentPage(),
            'last_page' => $notifications->lastPage(),
            'total' => $notifications->total(),
        ]);
    }
}
