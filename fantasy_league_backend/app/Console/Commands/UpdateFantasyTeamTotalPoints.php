<?php

namespace App\Console\Commands;

use App\Models\FantasyTeam;
use App\Models\MatchPlayerPoints;
use App\Models\Tournament;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

class UpdateFantasyTeamTotalPoints extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'fantasy-teams:update-total-points {--tournament_id= : Optional tournament ID to update specific tournament} {--batch=1000 : Number of teams to process per batch}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Calculate and update total_points for all fantasy teams (optimized for scale with batch processing)';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $this->info('🔄 Updating fantasy team total points...');

        $tournamentId = $this->option('tournament_id');
        $batchSize = (int)$this->option('batch');

        // If tournament_id is provided, verify tournament exists and has valid status
        if ($tournamentId) {
            $tournament = Tournament::find($tournamentId);

            if (!$tournament) {
                $this->error("❌ Tournament with ID {$tournamentId} not found.");
                return Command::FAILURE;
            }

            // Check if tournament status is 'running' or 'active'
            if (!in_array($tournament->status, ['running', 'active'])) {
                $this->warn("⚠️  Tournament '{$tournament->name}' has status '{$tournament->status}'. Only 'running' or 'active' tournaments can be processed.");
                $this->warn("✋ Skipping update for tournament ID: {$tournamentId}");
                return Command::SUCCESS;
            }

            $this->info("📊 Filtering by tournament ID: {$tournamentId}");
            $this->info("🟢 Tournament status: {$tournament->status}");
        }

        // Build query
        $query = FantasyTeam::query();

        if ($tournamentId) {
            $query->where('tournament_id', $tournamentId);
        }

        // Get total count for progress bar
        $total = $query->count();
        $this->info("📈 Processing {$total} teams in batches of {$batchSize}...");

        if ($total === 0) {
            $this->warn('⚠️  No teams to update.');
            return Command::SUCCESS;
        }

        $updated = 0;
        $errors = 0;
        $progressBar = $this->output->createProgressBar($total);
        $progressBar->start();

        // Process in chunks to avoid memory overload
        // This is critical for lacs (hundreds of thousands) of teams
        $query->chunk($batchSize, function ($teams) use (&$updated, &$errors, $progressBar) {
            foreach ($teams as $team) {
                try {
                    // Get tournament multipliers
                    $tournament = Tournament::find($team->tournament_id);
                    $captainMultiplier = $tournament->captain_multiplier ?? 2.0;
                    $viceCaptainMultiplier = $tournament->vice_captain_multiplier ?? 1.5;

                    // Calculate base points for all players
                    $basePoints = MatchPlayerPoints::query()
                        ->whereIn('player_id', $team->player_ids ?? [])
                        ->where('tournament_id', $team->tournament_id)
                        ->sum('points');

                    // Add captain bonus points
                    if ($team->captain_id) {
                        $captainPoints = MatchPlayerPoints::query()
                            ->where('player_id', $team->captain_id)
                            ->where('tournament_id', $team->tournament_id)
                            ->sum('points');
                        $basePoints += $captainPoints * ($captainMultiplier - 1);
                    }

                    // Add vice captain bonus points
                    if ($team->vice_captain_id) {
                        $viceCaptainPoints = MatchPlayerPoints::query()
                            ->where('player_id', $team->vice_captain_id)
                            ->where('tournament_id', $team->tournament_id)
                            ->sum('points');
                        $basePoints += $viceCaptainPoints * ($viceCaptainMultiplier - 1);
                    }

                    $totalPoints = (int)$basePoints;

                    // Update only changed total_points (reduces write load)
                    if ($team->total_points !== $totalPoints) {
                        $team->update(['total_points' => $totalPoints]);
                        $updated++;
                    }
                } catch (\Exception $e) {
                    $errors++;
                    $this->error("\n❌ Error updating team {$team->id}: {$e->getMessage()}");
                }

                $progressBar->advance();
            }

            // Explicit memory cleanup after each batch
            // Critical for processing hundreds of thousands of teams
            unset($teams);
            gc_collect_cycles();
        });

        $progressBar->finish();
        $this->info('');

        // Summary
        $this->info('');
        $this->info('═══════════════════════════════════════');
        $this->info("✅ Successfully updated: {$updated} teams");
        if ($errors > 0) {
            $this->error("❌ Errors: {$errors}");
        }
        $this->info("📊 Batch size: {$batchSize}");
        $this->info('═══════════════════════════════════════');

        return Command::SUCCESS;
    }
}
