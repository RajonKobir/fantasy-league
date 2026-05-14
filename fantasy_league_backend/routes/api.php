<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\ConfigController;
use App\Http\Controllers\Api\GameMatchController;
use App\Http\Controllers\Api\FantasyTeamController;
use App\Http\Controllers\Api\PlayerController;
use App\Http\Controllers\Api\PlayerSelectionController;
use App\Http\Controllers\Api\PaymentMethodController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

// -----------------------
// Public Auth Routes
// -----------------------
// Rate-limited auth endpoints to mitigate brute-force and abuse
Route::post('/login', [AuthController::class, 'login'])->middleware(['throttle:10,1', \App\Http\Middleware\RequireAppVersion::class]);
Route::post('/register', [AuthController::class, 'register'])->middleware(['throttle:5,1', \App\Http\Middleware\RequireAppVersion::class]);
Route::post('/verify-email', [AuthController::class, 'verifyEmail'])->middleware(['throttle:5,1', \App\Http\Middleware\RequireAppVersion::class]);
Route::post('/resend-verification-email', [AuthController::class, 'resendVerificationEmail'])->middleware(['throttle:3,1', \App\Http\Middleware\RequireAppVersion::class]);
// Test email route (remove in production)
Route::post('/test-email', function (Request $request) {
    $email = $request->email ?? 'test@example.com';
    $user = \App\Models\User::firstOrCreate(
        ['email' => $email],
        ['name' => 'Test User', 'password' => bcrypt('password')]
    );
    $user->sendEmailVerificationNotification();
    return response()->json(['message' => 'Test email sent to ' . $email]);
})->middleware(['throttle:5,1', \App\Http\Middleware\RequireAppVersion::class]);
// Social login (google/facebook) - accepts { provider: 'google'|'facebook', token: '<id_or_access_token>' }
Route::post('/social-login', [AuthController::class, 'socialLogin'])->middleware(['throttle:10,1', \App\Http\Middleware\RequireAppVersion::class]);
Route::middleware(['auth:sanctum', \App\Http\Middleware\RequireAppVersion::class])->post('/logout', [AuthController::class, 'logout']);
Route::middleware(['auth:sanctum', \App\Http\Middleware\RequireAppVersion::class])->get('/user', [AuthController::class, 'user']);

// Public config endpoint (returns keys that frontend can read)
Route::get('/config', [ConfigController::class, 'index']);
// Authenticated admin endpoint to update config keys (Sanctum + admin check)
Route::middleware(['auth:sanctum', \App\Http\Middleware\EnsureUserIsAdmin::class])->post('/config', [ConfigController::class, 'update']);
Route::middleware(['auth:sanctum', \App\Http\Middleware\EnsureUserIsAdmin::class])->delete('/config/{key}', [ConfigController::class, 'destroy']);

// All other API routes require clients to send X-App-Version header and match the minimum configured version
Route::middleware([\App\Http\Middleware\RequireAppVersion::class])->group(function () {

    // Payment Methods (public - for payment request forms)
    Route::get('/payment-methods', [\App\Http\Controllers\Api\PaymentMethodController::class, 'index'])->name('api.payment-methods.index');

    // Tournaments (public)
    Route::get('/tournaments', [\App\Http\Controllers\Api\TournamentController::class, 'index'])->name('api.tournaments.index');
    Route::get('/tournaments/{tournament}', [\App\Http\Controllers\Api\TournamentController::class, 'show'])->name('api.tournaments.show');
    Route::get('/tournaments/{tournament}/teams', [\App\Http\Controllers\Api\TournamentController::class, 'teams'])->name('api.tournaments.teams');
    Route::get('/tournaments/{tournament}/leaderboard', [\App\Http\Controllers\Api\TournamentController::class, 'leaderboard'])->name('api.tournaments.leaderboard');

// Countries & Cities (public, used for searchable dropdowns)
Route::get('/countries', [\App\Http\Controllers\Api\CountryController::class, 'index'])->name('api.countries.index');
Route::get('/countries/{country}', [\App\Http\Controllers\Api\CountryController::class, 'show'])->name('api.countries.show');
Route::get('/cities', [\App\Http\Controllers\Api\CityController::class, 'index'])->name('api.cities.index');
Route::get('/cities/{city}', [\App\Http\Controllers\Api\CityController::class, 'show'])->name('api.cities.show');

// Game teams public endpoints
Route::get('/teams', [\App\Http\Controllers\Api\TeamController::class, 'index'])->name('api.teams.index');
Route::get('/teams/{team}', [\App\Http\Controllers\Api\TeamController::class, 'show'])->name('api.teams.show');

// Winners (public - available to Flutter app)
Route::get('/tournaments/{tournament}/winners', [\App\Http\Controllers\Api\WinnersController::class, 'getTournamentWinners'])->name('api.tournaments.winners');

// Authenticated user endpoints
// (see below inside the main auth group for authenticated API routes)

// Admin-only CRUD for tournaments

// Admin-only CRUD for tournaments
Route::middleware(['auth:sanctum', \App\Http\Middleware\EnsureUserIsAdmin::class])->post('/tournaments', [\App\Http\Controllers\Api\TournamentController::class, 'store']);
Route::middleware(['auth:sanctum', \App\Http\Middleware\EnsureUserIsAdmin::class])->put('/tournaments/{tournament}', [\App\Http\Controllers\Api\TournamentController::class, 'update']);
Route::middleware(['auth:sanctum', \App\Http\Middleware\EnsureUserIsAdmin::class])->delete('/tournaments/{tournament}', [\App\Http\Controllers\Api\TournamentController::class, 'destroy']);

// -----------------------
// API Routes (authenticated via Sanctum)
// -----------------------
Route::middleware('auth:sanctum')->group(function () {

    // User profile
    // Accept both PUT and POST (POST for multipart file uploads which work better with multipart)
    Route::match(['put', 'post'], '/users/me', [AuthController::class, 'updateProfile']);

    // Players
    Route::get('/players', [PlayerController::class, 'index'])->name('api.players.index');

    // Admin-only player CRUD (image upload supported)
    Route::middleware([\App\Http\Middleware\EnsureUserIsAdmin::class])->post('/players', [PlayerController::class, 'store'])->name('api.players.store');
    Route::middleware([\App\Http\Middleware\EnsureUserIsAdmin::class])->put('/players/{player}', [PlayerController::class, 'update'])->name('api.players.update');
    Route::middleware([\App\Http\Middleware\EnsureUserIsAdmin::class])->delete('/players/{player}', [PlayerController::class, 'destroy'])->name('api.players.destroy');

    // Game Matches
    Route::get('/game-matches', [GameMatchController::class, 'index'])->name('api.game-matches.index');
    Route::get('/game-matches/{gameMatch}', [GameMatchController::class, 'show'])->name('api.game-matches.show');

    // Squads / Players for a match
    Route::get('/game-matches/{gameMatch}/players', [GameMatchController::class, 'players'])->name('api.game-matches.players');
    Route::get('/game-matches/{gameMatch}/squads', [GameMatchController::class, 'squads'])->name('api.game-matches.squads');

    // Admin-only Team management APIs
    Route::middleware([\App\Http\Middleware\EnsureUserIsAdmin::class])->put('/teams/{team}', [\App\Http\Controllers\Api\TeamController::class, 'update']);
    Route::middleware([\App\Http\Middleware\EnsureUserIsAdmin::class])->delete('/teams/{team}', [\App\Http\Controllers\Api\TeamController::class, 'destroy']);

    // Fantasy Teams (user-created teams for tournaments)
    Route::get('/fantasy-teams', [FantasyTeamController::class, 'index'])->name('api.fantasy-teams.index');
    Route::get('/fantasy-teams/{fantasyTeam}', [FantasyTeamController::class, 'show'])->name('api.fantasy-teams.show');
    Route::post('/fantasy-teams', [FantasyTeamController::class, 'store'])->name('api.fantasy-teams.store');
    Route::put('/fantasy-teams/{fantasyTeam}', [FantasyTeamController::class, 'update'])->name('api.fantasy-teams.update');
    Route::delete('/fantasy-teams/{fantasyTeam}', [FantasyTeamController::class, 'destroy'])->name('api.fantasy-teams.destroy');

    // Backwards-compatible endpoint: allow creating a fantasy team using legacy /api/teams POST
    Route::post('/teams', [\App\Http\Controllers\Api\FantasyTeamController::class, 'store']);

    // Current user: fetch teams owned by this user (game teams) — used by some clients
    Route::get('/me/teams', [\App\Http\Controllers\Api\TeamController::class, 'myTeams'])->name('api.me.teams');

    // -----------------------
    // Player Selections (legacy - will be deprecated in favor of FantasyTeams)
    // -----------------------
    Route::get('/teams/{team}/selections', [PlayerSelectionController::class, 'index'])
        ->name('api.teams.selections.index'); // List all player selections for a team

    Route::post('/teams/{team}/selections', [PlayerSelectionController::class, 'store'])
        ->name('api.teams.selections.store'); // Add a player selection

    Route::put('/teams/{team}/selections/{selection}', [PlayerSelectionController::class, 'update'])
        ->name('api.teams.selections.update'); // Update a selection (captain/vice-captain)

    Route::delete('/teams/{team}/selections/{selection}', [PlayerSelectionController::class, 'destroy'])
        ->name('api.teams.selections.destroy'); // Remove a player from the team

    // Wallet, Transactions, Notifications, Pan card
    // User wallet endpoint (returns balance + transactions)
    Route::get('/wallet', [\App\Http\Controllers\Api\WalletController::class, 'show'])->name('api.wallet.show');
    // Admin-only endpoint to manually credit a user's wallet
    Route::middleware([\App\Http\Middleware\EnsureUserIsAdmin::class])->post('/admin/users/{user}/wallet/credit', [\App\Http\Controllers\Api\WalletController::class, 'credit'])->name('api.admin.users.wallet.credit');
    Route::middleware([\App\Http\Middleware\EnsureUserIsAdmin::class])->post('/admin/users/{user}/wallet/adjust', [\App\Http\Controllers\Api\WalletController::class, 'adjust'])->name('api.admin.users.wallet.adjust');
    // Admin: fetch wallet audit logs for a user
    Route::middleware([\App\Http\Middleware\EnsureUserIsAdmin::class])->get('/admin/users/{user}/wallet/logs', [\App\Http\Controllers\Api\WalletController::class, 'logs'])->name('api.admin.users.wallet.logs');

    // Payment Requests
    Route::get('/payment-requests', [\App\Http\Controllers\Api\PaymentRequestController::class, 'userIndex'])->name('api.payment-requests.index');
    Route::post('/payment-requests', [\App\Http\Controllers\Api\PaymentRequestController::class, 'store'])->name('api.payment-requests.store');
    Route::get('/payment-requests/{paymentRequest}', [\App\Http\Controllers\Api\PaymentRequestController::class, 'show'])->name('api.payment-requests.show');

    // Cancel Requests (user-submitted when they want to cancel a fantasy team)
    Route::get('/cancel-requests', [\App\Http\Controllers\Api\CancelRequestController::class, 'userIndex'])->name('api.cancel-requests.index');
    Route::post('/cancel-requests', [\App\Http\Controllers\Api\CancelRequestController::class, 'store'])->name('api.cancel-requests.store');

    // Admin: payment request management
    Route::middleware([\App\Http\Middleware\EnsureUserIsAdmin::class])->get('/admin/payment-requests', [\App\Http\Controllers\Api\PaymentRequestController::class, 'adminIndex'])->name('api.admin.payment-requests.index');
    Route::middleware([\App\Http\Middleware\EnsureUserIsAdmin::class])->post('/admin/payment-requests/{paymentRequest}/approve', [\App\Http\Controllers\Api\PaymentRequestController::class, 'approve'])->name('api.admin.payment-requests.approve');
    Route::middleware([\App\Http\Middleware\EnsureUserIsAdmin::class])->post('/admin/payment-requests/{paymentRequest}/reject', [\App\Http\Controllers\Api\PaymentRequestController::class, 'reject'])->name('api.admin.payment-requests.reject');

    // Admin: cancel request management
    Route::middleware([\App\Http\Middleware\EnsureUserIsAdmin::class])->get('/admin/cancel-requests', [\App\Http\Controllers\Api\CancelRequestController::class, 'adminIndex'])->name('api.admin.cancel-requests.index');
    Route::middleware([\App\Http\Middleware\EnsureUserIsAdmin::class])->post('/admin/cancel-requests/{cancelRequest}/approve', [\App\Http\Controllers\Api\CancelRequestController::class, 'approve'])->name('api.admin.cancel-requests.approve');
    Route::middleware([\App\Http\Middleware\EnsureUserIsAdmin::class])->post('/admin/cancel-requests/{cancelRequest}/reject', [\App\Http\Controllers\Api\CancelRequestController::class, 'reject'])->name('api.admin.cancel-requests.reject');

    // Admin: user management (list/update/delete)
    Route::middleware([\App\Http\Middleware\EnsureUserIsAdmin::class])->get('/admin/users', [\App\Http\Controllers\Api\UserController::class, 'index'])->name('api.admin.users.index');
    Route::middleware([\App\Http\Middleware\EnsureUserIsAdmin::class])->put('/admin/users/{user}', [\App\Http\Controllers\Api\UserController::class, 'update'])->name('api.admin.users.update');
    Route::middleware([\App\Http\Middleware\EnsureUserIsAdmin::class])->delete('/admin/users/{user}', [\App\Http\Controllers\Api\UserController::class, 'destroy'])->name('api.admin.users.destroy');

    Route::get('/transactions', [\App\Http\Controllers\Api\TransactionController::class, 'index'])->name('api.transactions.index');
    Route::get('/notifications', [\App\Http\Controllers\Api\NotificationController::class, 'index'])->name('api.notifications.index');

    // Admin-only points management
    Route::middleware([\App\Http\Middleware\EnsureUserIsAdmin::class])->get('/admin/points', [\App\Http\Controllers\Api\Admin\PointsApiController::class, 'index'])->name('api.admin.points.index');
    Route::middleware([\App\Http\Middleware\EnsureUserIsAdmin::class])->post('/admin/points', [\App\Http\Controllers\Api\Admin\PointsApiController::class, 'store'])->name('api.admin.points.store');
    Route::middleware([\App\Http\Middleware\EnsureUserIsAdmin::class])->put('/admin/points/{point}', [\App\Http\Controllers\Api\Admin\PointsApiController::class, 'update'])->name('api.admin.points.update');
    Route::middleware([\App\Http\Middleware\EnsureUserIsAdmin::class])->delete('/admin/points/{point}', [\App\Http\Controllers\Api\Admin\PointsApiController::class, 'destroy'])->name('api.admin.points.destroy');
    // Admin: manually trigger cron job to update fantasy team points
    Route::middleware([\App\Http\Middleware\EnsureUserIsAdmin::class])->post('/admin/cron/update-fantasy-team-points', [\App\Http\Controllers\Api\Admin\PointsApiController::class, 'triggerCronJob'])->name('api.admin.cron.update-fantasy-team-points');

    // Current user: fetch points for (their) fantasy team for a tournament (requires auth)
    Route::get('/me/fantasy-team/points', [FantasyTeamController::class, 'myTeamPoints'])->name('api.me.fantasy_team.points');
});

});
