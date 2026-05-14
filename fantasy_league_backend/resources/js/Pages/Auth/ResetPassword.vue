<script setup>
import { Head, Link, useForm } from '@inertiajs/vue3'
import { usePage } from '@inertiajs/vue3'

const props = usePage().props.value
const token = props?.route?.params?.token || null

const form = useForm({ token: token || '', email: '', password: '', password_confirmation: '' })

function submit() {
  form.post('/reset-password')
}
</script>

<template>
  <Head title="Reset Password" />
  <div class="max-w-md mx-auto py-8">
    <h1 class="text-2xl font-semibold mb-4">Reset Password</h1>
    <form @submit.prevent="submit" class="space-y-4">
      <input v-model="form.token" type="hidden" />
      <div>
        <label class="block text-sm font-medium mb-1">Email</label>
        <input v-model="form.email" type="email" class="w-full border rounded px-3 py-2" />
      </div>
      <div>
        <label class="block text-sm font-medium mb-1">Password</label>
        <input v-model="form.password" type="password" class="w-full border rounded px-3 py-2" />
      </div>
      <div>
        <label class="block text-sm font-medium mb-1">Confirm Password</label>
        <input v-model="form.password_confirmation" type="password" class="w-full border rounded px-3 py-2" />
      </div>
      <button type="submit" class="px-4 py-2 bg-blue-600 text-white rounded">Reset Password</button>
    </form>
    <div class="mt-4">
      <Link href="/login" class="text-sm text-blue-600">Back to login</Link>
    </div>
  </div>
</template>
