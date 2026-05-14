<?php

namespace App\Jobs;

use App\Models\User;
use App\Notifications\VerifyEmailNotification;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Notification;
use Illuminate\Support\Facades\Log;

class SendVerificationEmailJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    protected $user;
    protected $verificationUrl;

    public $tries = 3;
    public $backoff = [10, 30, 60]; // Retry after 10, 30, 60 seconds
    public $timeout = 30;

    /**
     * Create a new job instance.
     */
    public function __construct(User $user, string $verificationUrl)
    {
        $this->user = $user;
        $this->verificationUrl = $verificationUrl;
    }

    /**
     * Execute the job.
     */
    public function handle(): void
    {
        try {
            Log::info('[SendVerificationEmailJob] Sending verification email to: ' . $this->user->email);

            Notification::send(
                $this->user,
                new VerifyEmailNotification($this->verificationUrl)
            );

            Log::info('[SendVerificationEmailJob] Successfully sent verification email to: ' . $this->user->email);
        } catch (\Exception $e) {
            Log::error('[SendVerificationEmailJob] Failed to send email: ' . $e->getMessage());
            throw $e; // Rethrow to trigger retry mechanism
        }
    }

    /**
     * Handle a job failure.
     */
    public function failed(\Throwable $exception): void
    {
        Log::error('[SendVerificationEmailJob] Job failed after retries: ' . $exception->getMessage());
        // Optional: Send alert to admin or perform cleanup
        Log::error('[SendVerificationEmailJob] Failed to send verification email to user: ' . $this->user->email);
    }
}
