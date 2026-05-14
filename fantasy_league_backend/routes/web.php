<?php

use App\Http\Controllers\Admin\PlayerSelectionController;
use App\Http\Controllers\ProfileController;
use App\Models\GameMatch;
use App\Models\Player;
use App\Models\Team;
use Illuminate\Foundation\Application;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Route;
use Inertia\Inertia;

// -----------------------
// Public Routes
// -----------------------
Route::get('/', function () {
    return Inertia::render('Welcome', [
        'canLogin' => Route::has('login'),
        'canRegister' => Route::has('register'),
        'laravelVersion' => Application::VERSION,
        'phpVersion' => PHP_VERSION,
    ]);
});

// -----------------------
// Dashboard (authenticated & verified users)
// -----------------------
// Redirect /dashboard to /admin/dashboard for admin users
Route::get('/dashboard', function () {
    if (Auth::check() && Auth::user()->is_admin) {
        return redirect('/admin/dashboard');
    }
    return Inertia::render('Dashboard', [
        'stats' => [
            'players' => Player::count(),
            'matches' => GameMatch::count(),
            'teams' => Team::count(),
        ],
        'matches' => GameMatch::orderBy('start_time')->get(),
    ]);
})->middleware(['auth', 'verified'])->name('dashboard');

// -----------------------
// Profile routes (authenticated)
// -----------------------
Route::middleware('auth')->group(function () {
    Route::get('/profile', [ProfileController::class, 'edit'])->name('profile.edit');
    Route::patch('/profile', [ProfileController::class, 'update'])->name('profile.update');
    Route::delete('/profile', [ProfileController::class, 'destroy'])->name('profile.destroy');
});

require __DIR__.'/auth.php';

// -----------------------
// Admin Routes (authenticated & verified)
// -----------------------
Route::middleware(['auth', 'verified', \App\Http\Middleware\EnsureUserIsAdmin::class])
    ->prefix('admin')
    ->name('admin.')
    ->group(function () {

        // Admin Dashboard
        Route::get('/dashboard', function () {
            return Inertia::render('Admin/Dashboard', [
                'stats' => [
                    'players' => Player::count(),
                    'matches' => GameMatch::count(),
                    'teams' => Team::count(),
                    'tournaments' => \App\Models\Tournament::count(),
                ],
                'matches' => GameMatch::orderBy('start_time')->get(),
            ]);
        })->name('dashboard');

        // Players CRUD
        Route::resource('players', \App\Http\Controllers\Admin\PlayerController::class);

        // Countries & Cities management (admin)
        Route::resource('countries', \App\Http\Controllers\Admin\CountryController::class);
        Route::resource('cities', \App\Http\Controllers\Admin\CityController::class);

        // Game Matches CRUD
        Route::resource('game-matches', \App\Http\Controllers\Admin\GameMatchController::class);

        // Match Player Points management
        Route::get('game-matches/{gameMatch}/points', [\App\Http\Controllers\Admin\MatchPlayerPointsController::class, 'show'])->name('game-matches.points.show');
        Route::post('game-matches/{gameMatch}/points', [\App\Http\Controllers\Admin\MatchPlayerPointsController::class, 'update'])->name('game-matches.points.update');
        Route::delete('game-matches/{gameMatch}/points/{player}', [\App\Http\Controllers\Admin\MatchPlayerPointsController::class, 'destroy'])->name('game-matches.points.destroy');

        // Admin cron UI (open in new tab) and SSE stream for long-running fantasy team points update
        Route::get('cron/update-fantasy-team-points', [\App\Http\Controllers\Admin\CronController::class, 'showStreamPage'])->name('cron.update-fantasy-team-points');
        Route::get('cron/update-fantasy-team-points/stream', [\App\Http\Controllers\Admin\CronController::class, 'streamUpdateFantasyTeamPoints'])->name('cron.update-fantasy-team-points.stream');

        // Teams CRUD + bulk actions
        Route::resource('teams', \App\Http\Controllers\Admin\TeamController::class);
        // Bulk actions for teams
        Route::post('teams/bulk', [\App\Http\Controllers\Admin\TeamController::class, 'bulk'])->name('teams.bulk');
        // Export
        Route::post('teams/export', [\App\Http\Controllers\Admin\TeamController::class, 'export'])->name('teams.export');

        // Player selections for a team (team-scoped edit + update)
        Route::get('teams/{team}/player-selections', [PlayerSelectionController::class, 'editTeam'])->name('teams.selections.edit');
        Route::post('teams/{team}/player-selections', [PlayerSelectionController::class, 'updateTeam'])->name('teams.selections.update');

        // Admin Profile
        Route::get('profile', [\App\Http\Controllers\Admin\AdminProfileController::class, 'show'])->name('profile.show');
        Route::post('profile', [\App\Http\Controllers\Admin\AdminProfileController::class, 'update'])->name('profile.update');
        Route::post('profile/password', [\App\Http\Controllers\Admin\AdminProfileController::class, 'updatePassword'])->name('profile.update-password');

        // App Settings (Admin editable)
        Route::get('settings', [\App\Http\Controllers\Admin\AppSettingsController::class, 'index'])->name('settings.index');
        Route::post('settings', [\App\Http\Controllers\Admin\AppSettingsController::class, 'update'])->name('settings.update');
        Route::post('settings/delete', [\App\Http\Controllers\Admin\AppSettingsController::class, 'destroy'])->name('settings.delete');

        // Users management (admin) - regular users only
        Route::resource('users', \App\Http\Controllers\Admin\UserController::class)->only(['index', 'create', 'store', 'edit', 'update', 'destroy']);

        // Admins management (admin-only users)
        Route::resource('admins', \App\Http\Controllers\Admin\AdminController::class)->only(['index', 'create', 'store', 'edit', 'update', 'destroy']);

        // Tournaments management
        Route::resource('tournaments', \App\Http\Controllers\Admin\TournamentController::class);
        Route::post('tournaments/{tournament}/assign-team', [\App\Http\Controllers\Admin\TournamentController::class, 'assignTeam'])->name('tournaments.assignTeam');
        Route::delete('tournaments/{tournament}/teams/{team}', [\App\Http\Controllers\Admin\TournamentController::class, 'removeTeam'])->name('tournaments.removeTeam');
        Route::post('tournaments/{tournament}/player-points', [\App\Http\Controllers\Admin\TournamentController::class, 'updatePlayerPoints'])->name('tournaments.playerPoints');

        // Points overview (per tournament)
        Route::get('points', [\App\Http\Controllers\Admin\PointController::class, 'index'])->name('points.index');
        Route::get('points/create', [\App\Http\Controllers\Admin\PointController::class, 'create'])->name('points.create');
        Route::post('points', [\App\Http\Controllers\Admin\PointController::class, 'store'])->name('points.store');
        Route::get('points/{point}/edit', [\App\Http\Controllers\Admin\PointController::class, 'edit'])->name('points.edit');
        Route::put('points/{point}', [\App\Http\Controllers\Admin\PointController::class, 'update'])->name('points.update');
        Route::delete('points/{point}', [\App\Http\Controllers\Admin\PointController::class, 'destroy'])->name('points.destroy');

        // Fantasy Teams (admin)
        Route::get('fantasy-teams', [\App\Http\Controllers\Admin\FantasyTeamController::class, 'index'])->name('fantasy-teams.index');
        Route::get('fantasy-teams/create', [\App\Http\Controllers\Admin\FantasyTeamController::class, 'create'])->name('fantasy-teams.create');
        Route::post('fantasy-teams', [\App\Http\Controllers\Admin\FantasyTeamController::class, 'store'])->name('fantasy-teams.store');
        Route::get('fantasy-teams/{fantasyTeam}/edit', [\App\Http\Controllers\Admin\FantasyTeamController::class, 'edit'])->name('fantasy-teams.edit');
        Route::put('fantasy-teams/{fantasyTeam}', [\App\Http\Controllers\Admin\FantasyTeamController::class, 'update'])->name('fantasy-teams.update');
        Route::delete('fantasy-teams/{fantasyTeam}', [\App\Http\Controllers\Admin\FantasyTeamController::class, 'destroy'])->name('fantasy-teams.destroy');

        // Cancel Requests management
        Route::get('cancel-requests', [\App\Http\Controllers\Admin\CancelRequestController::class, 'index'])->name('cancel-requests.index');
        Route::get('cancel-requests/create', [\App\Http\Controllers\Admin\CancelRequestController::class, 'create'])->name('cancel-requests.create');
        Route::post('cancel-requests', [\App\Http\Controllers\Admin\CancelRequestController::class, 'store'])->name('cancel-requests.store');
        Route::get('cancel-requests/{cancelRequest}', [\App\Http\Controllers\Admin\CancelRequestController::class, 'show'])->name('cancel-requests.show');
        Route::post('cancel-requests/{cancelRequest}/approve', [\App\Http\Controllers\Admin\CancelRequestController::class, 'approve'])->name('cancel-requests.approve');
        Route::post('cancel-requests/{cancelRequest}/reject', [\App\Http\Controllers\Admin\CancelRequestController::class, 'reject'])->name('cancel-requests.reject');
        Route::delete('cancel-requests/{cancelRequest}', [\App\Http\Controllers\Admin\CancelRequestController::class, 'destroy'])->name('cancel-requests.destroy');

        // Payment Requests management
        Route::get('payment-requests', [\App\Http\Controllers\Admin\PaymentRequestController::class, 'index'])->name('payment-requests.index');
        Route::get('payment-requests/create', [\App\Http\Controllers\Admin\PaymentRequestController::class, 'create'])->name('payment-requests.create');
        Route::post('payment-requests', [\App\Http\Controllers\Admin\PaymentRequestController::class, 'store'])->name('payment-requests.store');
        Route::get('payment-requests/{paymentRequest}', [\App\Http\Controllers\Admin\PaymentRequestController::class, 'show'])->name('payment-requests.show');
        Route::post('payment-requests/{paymentRequest}/approve', [\App\Http\Controllers\Admin\PaymentRequestController::class, 'approve'])->name('payment-requests.approve');
        Route::post('payment-requests/{paymentRequest}/reject', [\App\Http\Controllers\Admin\PaymentRequestController::class, 'reject'])->name('payment-requests.reject');

        // Payment Methods management
        Route::resource('payment-methods', \App\Http\Controllers\Admin\PaymentMethodController::class);

        // Player Roles management
        Route::get('player-roles', [\App\Http\Controllers\Admin\PlayerRoleController::class, 'index'])->name('player-roles.index');
        Route::get('player-roles/create', [\App\Http\Controllers\Admin\PlayerRoleController::class, 'create'])->name('player-roles.create');
        Route::post('player-roles', [\App\Http\Controllers\Admin\PlayerRoleController::class, 'store'])->name('player-roles.store');
        Route::get('player-roles/{playerRole}/edit', [\App\Http\Controllers\Admin\PlayerRoleController::class, 'edit'])->name('player-roles.edit');
        Route::put('player-roles/{playerRole}', [\App\Http\Controllers\Admin\PlayerRoleController::class, 'update'])->name('player-roles.update');
        Route::delete('player-roles/{playerRole}', [\App\Http\Controllers\Admin\PlayerRoleController::class, 'destroy'])->name('player-roles.destroy');

        // Winners management
        Route::get('winners', [\App\Http\Controllers\Admin\WinnersController::class, 'index'])->name('winners.index');
        Route::get('winners/manage', [\App\Http\Controllers\Admin\WinnersController::class, 'manage'])->name('winners.manage');
        Route::get('winners/{winner}/edit', [\App\Http\Controllers\Admin\WinnersController::class, 'edit'])->name('winners.edit');
        Route::put('winners/{winner}', [\App\Http\Controllers\Admin\WinnersController::class, 'update'])->name('winners.update');
        Route::post('winners/get-top-users', [\App\Http\Controllers\Admin\WinnersController::class, 'getTopUsers'])->name('winners.getTopUsers');
        Route::post('winners/save', [\App\Http\Controllers\Admin\WinnersController::class, 'saveWinners'])->name('winners.save');
        Route::delete('winners/{winner}', [\App\Http\Controllers\Admin\WinnersController::class, 'destroy'])->name('winners.destroy');
    });
