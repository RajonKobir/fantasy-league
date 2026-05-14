<script setup>
import { Head, Link } from '@inertiajs/vue3'
import { ref } from 'vue'
import AdminLayout from '@/Layouts/AdminLayout.vue'
import FileUpload from '@/Shared/FileUpload.vue'

defineOptions({
  layout: AdminLayout,
})

const previewUrl = ref(null)
const progress = ref(0)
const createLoading = ref(false)
const createError = ref(null)
const fieldErrors = ref({})

const form = ref({
  name: '',
  email: '',
  password: '',
  password_confirmation: '',
  avatar: null,
})

function onFileSelected(file) {
  form.value.avatar = file || null
  previewUrl.value = file ? URL.createObjectURL(file) : null
}

function removeAvatar() {
  form.value.avatar = null
  previewUrl.value = null
}

async function submit() {
  progress.value = 0
  createLoading.value = true
  createError.value = null
  fieldErrors.value = {}

  try {
    // Build FormData
    const formData = new FormData()
    formData.append('name', form.value.name)
    formData.append('email', form.value.email)
    formData.append('password', form.value.password)
    formData.append('password_confirmation', form.value.password_confirmation)
    if (form.value.avatar) {
      formData.append('avatar', form.value.avatar)
    }

    // Get CSRF token from meta tag
    const token = document.querySelector('meta[name="csrf-token"]')?.content

    const response = await fetch(route('admin.users.store'), {
      method: 'POST',
      headers: {
        'Accept': 'application/json',
        'X-Requested-With': 'XMLHttpRequest',
        'X-CSRF-Token': token || '',
      },
      body: formData,
    })

    if (!response.ok) {
      const errorData = await response.json()

      // Display validation errors if available
      if (errorData.errors && typeof errorData.errors === 'object') {
        fieldErrors.value = errorData.errors
        // Create a readable error message from all errors
        const errorMessages = Object.values(errorData.errors).flat()
        createError.value = errorMessages.join(' ')
      } else {
        createError.value = errorData.message || 'Failed to create user. Please check your inputs.'
      }
      return
    }

    // Redirect to users list on success
    window.location.href = route('admin.users.index')
  } catch (error) {
    createError.value = 'Failed to create user. Please try again.'
  } finally {
    createLoading.value = false
    progress.value = 0
  }
}
</script>

<template>
  <Head title="Create User" />

  <div>
    <div class="flex justify-between items-center mb-6">
      <h1 class="text-2xl font-bold">Create User</h1>
      <Link
        href="/admin/users"
        class="px-4 py-2 bg-gray-700 text-white rounded-lg hover:bg-gray-900"
      >
        ⬅ Back
      </Link>
    </div>

    <div class="bg-white shadow rounded-lg p-6 max-w-md">
      <form @submit.prevent="submit" class="space-y-4">
        <div>
          <label class="block text-sm font-medium mb-1">Name *</label>
          <input
            v-model="form.name"
            type="text"
            class="w-full border rounded px-3 py-2"
            :class="{ 'border-red-500 bg-red-50': fieldErrors.name }"
          />
          <div v-if="fieldErrors.name" class="text-red-600 text-xs mt-1">
            {{ fieldErrors.name.join(', ') }}
          </div>
        </div>

        <div>
          <label class="block text-sm font-medium mb-1">Email *</label>
          <input
            v-model="form.email"
            type="email"
            class="w-full border rounded px-3 py-2"
            :class="{ 'border-red-500 bg-red-50': fieldErrors.email }"
          />
          <div v-if="fieldErrors.email" class="text-red-600 text-xs mt-1">
            {{ fieldErrors.email.join(', ') }}
          </div>
        </div>

        <div>
          <label class="block text-sm font-medium mb-1">Password *</label>
          <input
            v-model="form.password"
            type="password"
            class="w-full border rounded px-3 py-2"
            :class="{ 'border-red-500 bg-red-50': fieldErrors.password }"
          />
          <div v-if="fieldErrors.password" class="text-red-600 text-xs mt-1">
            {{ fieldErrors.password.join(', ') }}
          </div>
        </div>

        <div>
          <label class="block text-sm font-medium mb-1">Confirm Password *</label>
          <input
            v-model="form.password_confirmation"
            type="password"
            class="w-full border rounded px-3 py-2"
            :class="{ 'border-red-500 bg-red-50': fieldErrors.password_confirmation }"
          />
          <div v-if="fieldErrors.password_confirmation" class="text-red-600 text-xs mt-1">
            {{ fieldErrors.password_confirmation.join(', ') }}
          </div>
        </div>

        <!-- Avatar Upload -->
        <div>
          <FileUpload label="Avatar" :initial-preview="previewUrl" :progress="progress" @file-changed="onFileSelected" />
          <div v-if="previewUrl" class="mt-2 flex items-center gap-3">
            <img :src="previewUrl" class="h-24 w-24 object-cover rounded" />
            <button @click.prevent="removeAvatar" class="px-2 py-1 text-sm border rounded text-red-600 hover:bg-red-50">Remove avatar</button>
          </div>
        </div>

        <div class="flex gap-2 pt-2">
          <button
            type="submit"
            :disabled="createLoading"
            class="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 disabled:bg-gray-400 disabled:cursor-not-allowed"
          >
            <span v-if="createLoading">Creating...</span>
            <span v-else>Create User</span>
          </button>
        </div>

        <!-- Error Message -->
        <div v-if="createError" class="p-3 bg-red-100 text-red-800 rounded">
          {{ createError }}
        </div>
      </form>
    </div>
  </div>
</template>
