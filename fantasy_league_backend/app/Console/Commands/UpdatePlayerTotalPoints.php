<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;

class UpdatePlayerTotalPoints extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'players:update-total-points';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'DEPRECATED: Player totals are now calculated on-the-fly. Use Player::getTotalPoints($tournamentId) instead.';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $this->info('ℹ️  This command is no longer needed.');
        $this->line('');
        $this->info('Player totals are now calculated dynamically:');
        $this->line('');
        $this->line('  // Get tournament-specific total');
        $this->line('  $player->getTotalPoints($tournamentId)');
        $this->line('');
        $this->line('  // Get overall total across all tournaments');
        $this->line('  $player->getTotalPoints()');
        $this->line('');
        $this->line('  // Get points for specific match');
        $this->line('  $player->getMatchPoints($matchId)');
        $this->line('');
        $this->info('✅ Calculations are always current (no cron job needed)');
        $this->line('');

        return Command::SUCCESS;
    }
}

