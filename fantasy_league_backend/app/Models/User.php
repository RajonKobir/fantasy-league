<?php

namespace App\Models;

use Illuminate\Contracts\Auth\MustVerifyEmail;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Casts\Attribute;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable implements MustVerifyEmail
{
    /** @use HasFactory<\Database\Factories\UserFactory> */
    use HasApiTokens, HasFactory, Notifiable;

    /**
     * The attributes that are mass assignable.
     *
     * @var list<string>
     */
    protected $fillable = [
        'name',
        'email',
        'email_pending',
        'password',
        'is_admin',
        'wallet_balance',
        'avatar_url',
        'email_verified_at',
    ];

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var list<string>
     */
    protected $hidden = [
        'password',
        'remember_token',
        'email_pending',
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
            'is_admin' => 'boolean',
            'wallet_balance' => 'decimal:2',
        ];
    }

    /**
     * Get the avatar URL as a full HTTP URL (not a relative path).
     * Converts avatars/2/filename.jpg to http://domain/storage/avatars/2/filename.jpg
     */
    protected function avatarUrl(): Attribute
    {
        return Attribute::make(
            get: fn ($value) => $value ? url('storage/' . $value) : '',
        );
    }

    // Relationships

    public function transactions()
    {
        return $this->hasMany(\App\Models\Transaction::class);
    }

    public function notifications()
    {
        return $this->hasMany(\App\Models\UserNotification::class);
    }

    /**
     * Get payment requests submitted by this user
     */
    public function paymentRequests()
    {
        return $this->hasMany(\App\Models\PaymentRequest::class);
    }

    /**
     * Get payment requests approved by this admin
     */
    public function approvedPaymentRequests()
    {
        return $this->hasMany(\App\Models\PaymentRequest::class, 'approved_by');
    }

    /**
     * Send the email verification notification.
     * This method is called automatically when the user is registered.
     */
    public function sendEmailVerificationNotification()
    {
        // Use the frontend app URL from env or fallback to a default
        $frontendUrl = env('FRONTEND_URL', 'http://localhost:3000');
        $verificationUrl = $frontendUrl . '/verify-email?email=' . urlencode($this->email);
        $this->notify(new \App\Notifications\VerifyEmailNotification($verificationUrl));
    }
}
