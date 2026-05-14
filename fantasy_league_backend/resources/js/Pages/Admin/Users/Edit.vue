<script setup>
import { Head, Link } from '@inertiajs/vue3'
import { ref, watch, computed, onMounted } from 'vue'
import AdminLayout from '@/Layouts/AdminLayout.vue'
import FileUpload from '@/Shared/FileUpload.vue'

const props = defineProps({
  user: {
    type: Object,
    default: () => ({
      name: '',
      email: '',
      avatar_url: null,
    }),
  },
})

const previewUrl = ref(null)
const progress = ref(0)
const updateLoading = ref(false)
const updateSuccess = ref(null)
const updateError = ref(null)

// Initialize form with safe defaults
const form = ref({
  name: '',
  email: '',
  password: '',
  password_confirmation: '',
  avatar: null,
  remove_avatar: false,
})

// Track original user data for change detection
const originalData = ref({
  name: '',
  email: '',
  avatar_url: null,
})

// Initialize on mount with props data
onMounted(() => {
  if (props.user) {
    form.value = {
      name: props.user.name || '',
      email: props.user.email || '',
      password: '',
      password_confirmation: '',
      avatar: null,
      remove_avatar: false,
    }
    originalData.value = {
      name: props.user.name || '',
      email: props.user.email || '',
      avatar_url: props.user.avatar_url || null,
    }
    previewUrl.value = props.user.avatar_url || null
  }
})

// Check if form has any changes
const hasChanges = computed(() => {
  const nameChanged = form.value.name !== originalData.value.name
  const emailChanged = form.value.email !== originalData.value.email
  const passwordChanged = form.value.password !== '' || form.value.password_confirmation !== ''
  const avatarChanged = form.value.avatar !== null
  const removeAvatarChanged = form.value.remove_avatar

  return nameChanged || emailChanged || passwordChanged || avatarChanged || removeAvatarChanged
})

// Watch for changes in user prop and sync form
watch(() => props.user, (newUser) => {
  if (newUser) {
    form.value.name = newUser.name || ''
    form.value.email = newUser.email || ''
    form.value.password = ''
    form.value.password_confirmation = ''
    previewUrl.value = newUser.avatar_url || null

    // Update original data
    originalData.value = {
      name: newUser.name || '',
      email: newUser.email || '',
      avatar_url: newUser.avatar_url || null,
    }
  }
}, { deep: true })

function onFileSelected(file) {
  form.value.avatar = file || null
  form.value.remove_avatar = false
  previewUrl.value = file ? URL.createObjectURL(file) : props.user?.avatar_url || null
}

function removeAvatar() {
  form.value.avatar = null
  form.value.remove_avatar = true
  previewUrl.value = null
}

async function submit() {
  progress.value = 0
  updateLoading.value = true
  updateSuccess.value = null
  updateError.value = null

  try {
    // Manually build FormData to ensure all fields are included
    const formData = new FormData()
    formData.append('name', form.value.name)
    formData.append('email', form.value.email)
    formData.append('password', form.value.password)
    formData.append('password_confirmation', form.value.password_confirmation)
    if (form.value.avatar) {
      formData.append('avatar', form.value.avatar)
    }
    if (form.value.remove_avatar) {
      formData.append('remove_avatar', '1')
    }
    formData.append('_method', 'PUT')

    // Get CSRF token from meta tag
    const token = document.querySelector('meta[name="csrf-token"]')?.content

    const response = await fetch(route('admin.users.update', props.user.id), {
      method: 'POST',
      headers: {
        'Accept': 'application/json',
        'X-Requested-With': 'XMLHttpRequest',
        'X-CSRF-Token': token || '',
      },
      body: formData,
    })

    const data = await response.json()

    if (!response.ok) {
      // Display validation errors from server
      if (data.errors) {
        const errorMessages = Object.values(data.errors)
          .flat()
          .join('\n')
        updateError.value = errorMessages
      } else if (data.message) {
        updateError.value = data.message
      } else {
        updateError.value = 'Failed to update user. Please check your inputs.'
      }
      return
    }

    updateSuccess.value = data.message || 'User updated successfully.'

    // Reload the page to get fresh data
    setTimeout(() => {
      window.location.reload()
    }, 1500)
  } catch (error) {
    // Update failed
    updateError.value = 'Failed to update user. Please try again.'
  } finally {
    updateLoading.value = false
    progress.value = 0
  }
}
</script>

<template>
  <Head title="Edit User" />

  <AdminLayout>
    <div class="flex justify-between items-center mb-6">
      <h1 class="text-2xl font-bold">Edit User</h1>
      <Link href="/admin/users" class="px-4 py-2 bg-gray-700 text-white rounded-lg hover:bg-gray-900">⬅ Back</Link>
    </div>

    <form @submit.prevent="submit" class="space-y-4 max-w-full sm:max-w-md">
      <!-- Name Field -->
      <div>
        <label class="block text-sm font-medium mb-1">Name</label>
        <input v-model="form.name" type="text" class="w-full border rounded px-3 py-2" />
      </div>

      <!-- Email Field -->
      <div>
        <label class="block text-sm font-medium mb-1">Email</label>
        <input v-model="form.email" type="email" class="w-full border rounded px-3 py-2" />
      </div>

      <!-- Password Fields -->
      <div>
        <label class="block text-sm font-medium mb-1">Password (leave blank to keep current)</label>
        <input v-model="form.password" type="password" class="w-full border rounded px-3 py-2" />
      </div>

      <div>
        <label class="block text-sm font-medium mb-1">Confirm Password</label>
        <input v-model="form.password_confirmation" type="password" class="w-full border rounded px-3 py-2" />
      </div>

      <!-- Avatar Upload -->
      <div>
        <FileUpload label="Avatar" :initial-preview="previewUrl" :progress="progress" @file-changed="onFileSelected" />
        <div v-if="previewUrl" class="mt-2 flex items-center gap-3">
          <img :src="previewUrl" class="h-24 w-24 object-cover rounded" />
          <button @click.prevent="removeAvatar" class="px-2 py-1 text-sm border rounded text-red-600 hover:bg-red-50">Remove avatar</button>
        </div>
      </div>

      <!-- Submit Button -->
      <button
        type="submit"
        :disabled="!hasChanges || updateLoading"
        class="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 disabled:bg-gray-400 disabled:cursor-not-allowed"
      >
        <span v-if="updateLoading">Updating...</span>
        <span v-else>Update User</span>
      </button>

      <!-- Success/Error Messages -->
      <div v-if="updateSuccess" class="p-3 bg-green-100 text-green-800 rounded">
        {{ updateSuccess }}
      </div>
      <div v-if="updateError" class="p-3 bg-red-100 text-red-800 rounded">
        {{ updateError }}
      </div>
    </form>
  </AdminLayout>
</template>
