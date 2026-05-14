<script setup>
import { useForm, Head } from '@inertiajs/vue3'
import AdminLayout from '@/Layouts/AdminLayout.vue'
import { ref } from 'vue'

defineOptions({
  layout: AdminLayout,
})

const props = defineProps({
  user: {
    type: Object,
    required: true
  }
})

const form = useForm({
  name: props.user.name,
  email: props.user.email,
  avatar_url: null, // Will be set by file input
  remove_avatar: false,
  password: '',
  password_confirmation: '',
})

const avatar_preview = ref(props.user.avatar_url || null)
const file_input = ref(null)
const show_password_section = ref(false)

const handleAvatarSelect = (event) => {
  const file = event.target.files[0]
  if (file) {
    // Set the file in the form for upload
    form.avatar_url = file
    form.remove_avatar = false

    // Show preview locally
    const reader = new FileReader()
    reader.onload = (e) => {
      avatar_preview.value = e.target.result
    }
    reader.readAsDataURL(file)
  }
}

const removeAvatar = () => {
  form.avatar_url = null
  form.remove_avatar = true
  avatar_preview.value = null
  if (file_input.value) {
    file_input.value.value = ''
  }
}

const submit = () => {
  form.post(route('admin.profile.update'), {
    preserveScroll: true,
    forceFormData: true, // Ensures multipart/form-data for file uploads
  })
}

const submitPassword = () => {
  form.post(route('admin.profile.update-password'), {
    preserveScroll: true,
  })
}
</script>

<template>
  <div class="max-w-2xl mx-auto">
    <!-- Header -->
    <div class="mb-8">
      <h1 class="text-3xl font-bold text-gray-900">My Profile</h1>
      <p class="text-gray-600 mt-2">Manage your account settings and preferences</p>
    </div>

    <!-- Profile Information Card -->
    <div class="bg-white rounded-lg shadow-md p-8 mb-6">
      <h2 class="text-xl font-semibold text-gray-900 mb-6">Profile Information</h2>

      <div class="flex flex-col md:flex-row gap-8">
        <!-- Avatar section -->
        <div class="flex flex-col items-center">
          <img
            :src="avatar_preview || 'https://ui-avatars.com/api/?name=' + encodeURIComponent(form.name || 'Admin')"
            :alt="form.name"
            class="w-32 h-32 rounded-full object-cover border-4 border-blue-500 mb-4"
          />
          <button
            @click="$refs.file_input.click()"
            class="px-4 py-2 btn-primary text-sm mb-2"
          >
            Change Avatar
          </button>
          <button
            v-if="avatar_preview || props.user.avatar_url"
            @click.prevent="removeAvatar"
            class="px-4 py-2 text-sm border rounded text-red-600 hover:bg-red-50"
          >
            Remove Avatar
          </button>
          <input
            ref="file_input"
            type="file"
            accept="image/*"
            class="hidden"
            @change="handleAvatarSelect"
          />
          <p v-if="form.errors.avatar_url" class="mt-2 text-sm text-red-600">{{ form.errors.avatar_url }}</p>
        </div>

        <!-- Form fields -->
        <form @submit.prevent="submit" class="flex-1 space-y-4">
          <!-- Name -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Name</label>
            <input
              v-model="form.name"
              type="text"
              class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            />
            <p v-if="form.errors.name" class="mt-1 text-sm text-red-600">{{ form.errors.name }}</p>
          </div>

          <!-- Email -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Email</label>
            <input
              v-model="form.email"
              type="email"
              class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            />
            <p v-if="form.errors.email" class="mt-1 text-sm text-red-600">{{ form.errors.email }}</p>
          </div>

          <!-- Submit -->
          <div class="pt-4">
            <button
              type="submit"
              :disabled="form.processing"
              class="w-full px-4 py-2 btn-primary"
            >
              {{ form.processing ? 'Saving...' : 'Save Changes' }}
            </button>
          </div>
        </form>
      </div>
    </div>

    <!-- Password Change Card -->
    <div class="bg-white rounded-lg shadow-md p-8">
      <div class="flex items-center justify-between mb-6">
        <h2 class="text-xl font-semibold text-gray-900">Change Password</h2>
        <button
          @click="show_password_section = !show_password_section"
          class="text-sm text-blue-600 hover:text-blue-700 font-medium"
        >
          {{ show_password_section ? 'Hide' : 'Show' }}
        </button>
      </div>

      <form v-if="show_password_section" @submit.prevent="submitPassword" class="space-y-4">
        <!-- Current Password (if needed for security) -->
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">New Password</label>
          <input
            v-model="form.password"
            type="password"
            placeholder="Enter new password"
            class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
          />
          <p v-if="form.errors.password" class="mt-1 text-sm text-red-600">{{ form.errors.password }}</p>
        </div>

        <!-- Password confirmation -->
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Confirm Password</label>
          <input
            v-model="form.password_confirmation"
            type="password"
            placeholder="Confirm new password"
            class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
          />
          <p v-if="form.errors.password_confirmation" class="mt-1 text-sm text-red-600">{{ form.errors.password_confirmation }}</p>
        </div>

        <!-- Password requirements -->
        <div class="bg-blue-50 border border-blue-200 rounded-lg p-4 mt-4">
          <p class="text-sm text-blue-900 font-medium mb-2">Password requirements:</p>
          <ul class="text-xs text-blue-800 space-y-1">
            <li>• At least 8 characters long</li>
            <li>• Mix of uppercase and lowercase letters</li>
            <li>• At least one number</li>
            <li>• At least one special character (!@#$%^&*)</li>
          </ul>
        </div>

        <!-- Submit -->
        <div class="pt-4">
          <button
            type="submit"
            :disabled="form.processing"
            class="w-full px-4 py-2 btn-danger"
          >
            {{ form.processing ? 'Updating...' : 'Update Password' }}
          </button>
        </div>
      </form>

      <p v-else class="text-gray-600 text-sm">Click "Show" to change your password</p>
    </div>
  </div>
</template>
