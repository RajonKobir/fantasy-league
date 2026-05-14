<script setup>
import { Head, Link, useForm } from '@inertiajs/vue3'

const form = useForm({
  name: '',
  email: '',
  password: '',
  password_confirmation: '',
})

const submit = () => {
  form.post('/register')
}
</script>

<template>
  <Head title="Register" />
  <div class="flex items-center justify-center h-screen bg-gray-100">
    <div class="w-full max-w-md bg-white p-8 shadow rounded-lg">
      <h1 class="text-2xl font-bold mb-6">Register</h1>
      <form @submit.prevent="submit" class="space-y-4">
        <div>
          <label class="block text-sm font-medium">Name</label>
          <input v-model="form.name" type="text" class="mt-1 w-full border rounded px-3 py-2" />
        </div>
        <div>
          <label class="block text-sm font-medium">Email</label>
          <input v-model="form.email" type="email" class="mt-1 w-full border rounded px-3 py-2" />
        </div>
        <div>
          <label class="block text-sm font-medium">Password</label>
          <input v-model="form.password" type="password" class="mt-1 w-full border rounded px-3 py-2" />
        </div>
        <div>
          <label class="block text-sm font-medium">Confirm Password</label>
          <input v-model="form.password_confirmation" type="password" class="mt-1 w-full border rounded px-3 py-2" />
        </div>
        <button type="submit" class="w-full bg-green-600 text-white py-2 rounded hover:bg-green-700">
          Register
        </button>
        <p class="text-sm mt-4">
          Already have an account? <Link href="/login" class="text-blue-600 hover:underline">Login</Link>
        </p>
      </form>
    </div>
  </div>
</template>
