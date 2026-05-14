<?php

namespace App\Jobs;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Log;

class SendVerificationCodeEmailJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    protected $email;
    protected $token;

    public $tries = 3;
    public $backoff = [10, 30, 60]; // Retry after 10, 30, 60 seconds
    public $timeout = 30;

    /**
     * Create a new job instance.
     */
    public function __construct(string $email, string $token)
    {
        $this->email = $email;
        $this->token = $token;
    }

    /**
     * Execute the job.
     */
    public function handle(): void
    {
        try {
            Log::info('[SendVerificationCodeEmailJob] Sending verification code email to: ' . $this->email);

            Mail::raw("Your verification code: {$this->token}", function ($m) {
                $m->to($this->email)->subject('Verify your email');
            });

            Log::info('[SendVerificationCodeEmailJob] Successfully sent verification code to: ' . $this->email);
        } catch (\Exception $e) {
            Log::error('[SendVerificationCodeEmailJob] Failed to send email: ' . $e->getMessage());
            throw $e; // Rethrow to trigger retry mechanism
        }
    }

    /**
     * Handle a job failure.
     */
    public function failed(\Throwable $exception): void
    {
        Log::error('[SendVerificationCodeEmailJob] Job failed after retries for email: ' . $this->email);
        Log::error('[SendVerificationCodeEmailJob] Error: ' . $exception->getMessage());
        // Optional: Send alert to admin or perform cleanup
    }
}
