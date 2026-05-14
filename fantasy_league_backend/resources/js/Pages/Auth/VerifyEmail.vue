<script setup>
import { Head, Link } from '@inertiajs/vue3'
</script>

<template>
  <Head title="Verify Email" />
  <div class="max-w-md mx-auto py-8">
    <h1 class="text-2xl font-semibold mb-4">Verify Your Email Address</h1>
    <p class="mb-4">Please check your email for a verification link.</p>
    <Link href="/login" class="text-sm text-blue-600">Back to login</Link>
  </div>
</template>
