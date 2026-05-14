<?php

namespace App\Notifications;

use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;

class VerifyEmailNotification extends Notification implements ShouldQueue
{
    use Queueable;

    public $verificationUrl;

    public $tries = 3;
    public $timeout = 30;

    public function __construct($verificationUrl)
    {
        $this->verificationUrl = $verificationUrl;
        $this->onQueue('default'); // Send to default queue
    }

    public function via($notifiable)
    {
        return ['mail'];
    }

    public function toMail($notifiable)
    {
        $verificationCode = hash('sha256', $notifiable->getKey() . $notifiable->email);

        return (new MailMessage)
            ->subject('Verify Your Email Address - Game Fantasy')
            ->greeting('Hello ' . $notifiable->name . '!')
            ->line('Thank you for registering with Game Fantasy!')
            ->line('Please click the button below to verify your email address.')
            ->action('Verify Email', $this->verificationUrl . '?code=' . $verificationCode)
            ->line('Or copy this verification code and paste it in the app:')
            ->line('**Verification Code: ' . $verificationCode . '**')
            ->line('Or copy this link in your browser:')
            ->line($this->verificationUrl . '?code=' . $verificationCode)
            ->line('This verification code will expire in 24 hours.')
            ->line('If you did not create this account, please disregard this email.')
            ->salutation('Best regards,')
            ->from(config('mail.from.address'), config('mail.from.name'));
    }
}
