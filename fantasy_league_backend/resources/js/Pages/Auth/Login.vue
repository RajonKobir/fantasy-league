<script setup>
import { Head, Link, useForm } from '@inertiajs/vue3'

const form = useForm({
  email: '',
  password: '',
  remember: false,
})

const submit = () => {
  form.post('/login')
}
</script>

<template>
  <Head title="Login" />
  <div class="flex items-center justify-center h-screen bg-gray-100">
    <div class="w-full max-w-md bg-white p-8 shadow rounded-lg">
      <h1 class="text-2xl font-bold mb-6">Login</h1>
      <form @submit.prevent="submit" class="space-y-4">
        <div>
          <label class="block text-sm font-medium">Email</label>
          <input v-model="form.email" type="email" class="mt-1 w-full border rounded px-3 py-2" />
        </div>
        <div>
          <label class="block text-sm font-medium">Password</label>
          <input v-model="form.password" type="password" class="mt-1 w-full border rounded px-3 py-2" />
        </div>
        <div class="flex items-center">
          <input type="checkbox" v-model="form.remember" class="mr-2" />
          <span class="text-sm">Remember me</span>
        </div>
        <button type="submit" class="w-full bg-blue-600 text-white py-2 rounded hover:bg-blue-700">
          Login
        </button>

      </form>
    </div>
  </div>
</template>
