<script setup>
import { Head, Link, useForm } from '@inertiajs/vue3'

const form = useForm({ email: '' })

function submit() {
  form.post('/forgot-password')
}
</script>

<template>
  <Head title="Forgot Password" />
  <div class="max-w-md mx-auto py-8">
    <h1 class="text-2xl font-semibold mb-4">Forgot Password</h1>
    <form @submit.prevent="submit" class="space-y-4">
      <div>
        <label class="block text-sm font-medium mb-1">Email</label>
        <input v-model="form.email" type="email" class="w-full border rounded px-3 py-2" />
      </div>
      <button type="submit" class="px-4 py-2 bg-blue-600 text-white rounded">Send Reset Link</button>
    </form>
    <div class="mt-4">
      <Link href="/login" class="text-sm text-blue-600">Back to login</Link>
    </div>
  </div>
</template>
