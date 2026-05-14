<script setup>
import { Head, Link, useForm } from '@inertiajs/vue3'

const form = useForm({ password: '' })

function submit() {
  form.post('/confirm-password')
}
</script>

<template>
  <Head title="Confirm Password" />
  <div class="max-w-md mx-auto py-8">
    <h1 class="text-2xl font-semibold mb-4">Confirm Password</h1>
    <form @submit.prevent="submit" class="space-y-4">
      <div>
        <label class="block text-sm font-medium mb-1">Password</label>
        <input v-model="form.password" type="password" class="w-full border rounded px-3 py-2" />
      </div>
      <button type="submit" class="px-4 py-2 bg-blue-600 text-white rounded">Confirm</button>
    </form>
    <div class="mt-4">
      <Link href="/login" class="text-sm text-blue-600">Back to login</Link>
    </div>
  </div>
</template>
