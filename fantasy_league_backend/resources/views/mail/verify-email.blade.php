@component('mail::message')
# Verify Your Email Address

Hello {{ $user->name }},

Thank you for registering with **Game Fantasy**! To complete your registration, please verify your email address by clicking the button below.

@component('mail::button', ['url' => $verificationUrl])
Verify Email Address
@endcomponent

Or copy this link in your browser:
{{ $verificationUrl }}

This verification link will expire in 24 hours.

If you did not create this account, please disregard this email.

Thanks,<br>
{{ config('app.name') }}
@endcomponent
