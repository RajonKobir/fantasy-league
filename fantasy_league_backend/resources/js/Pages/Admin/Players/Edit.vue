<script setup>
import { Head, Link } from '@inertiajs/vue3'
import { ref, computed, onMounted } from 'vue'
import AdminLayout from '@/Layouts/AdminLayout.vue'
import FileUpload from '@/Shared/FileUpload.vue'
import SearchableSelect from '@/Components/SearchableSelect.vue'

const props = defineProps({
  player: {
    type: Object,
    default: () => ({}),
  },
  roles: Array,
  countries: Array,
})

const previewUrl = ref(null)
const progress = ref(0)
const updateLoading = ref(false)
const formErrors = ref({})

const form = ref(null)

const originalData = ref(null)

// Initialize form and originalData when player prop is received
onMounted(() => {
  if (props.player && props.player.id) {
    // Try to match country_id from nationality if not set
    let countryId = props.player.country_id || ''
    if (!countryId && props.player.nationality && props.countries && props.countries.length) {
      const match = props.countries.find(c => (c.name || '').trim().toLowerCase() === (props.player.nationality || '').trim().toLowerCase())
      if (match) countryId = match.id
    }
    // Try to match player_role_id from role name if not set, case-insensitive and trimmed
    let playerRoleId = props.player.player_role_id || ''
    if (!playerRoleId && props.player.role && props.roles && props.roles.length) {
      const matchRole = props.roles.find(r => (r.name || '').trim().toLowerCase() === (props.player.role || '').trim().toLowerCase())
      if (matchRole) playerRoleId = matchRole.id
    }
    form.value = {
      name: props.player.name || '',
      player_role_id: playerRoleId || '',
      nationality: props.player.nationality || '',
      country_id: countryId || '',
      image: null,
      remove_image: false,
    }
    originalData.value = {
      name: props.player.name || '',
      player_role_id: playerRoleId || '',
      nationality: props.player.nationality || '',
      country_id: countryId || '',
    }
    previewUrl.value = props.player.image_url || null
  }
})

const countryOptions = computed(() => (props.countries || []).map(c => ({ id: c.id, label: c.name })))

const hasChanges = computed(() => {
  if (!form.value || !originalData.value) return false

  const nameChanged = form.value.name !== originalData.value.name
  const roleChanged = form.value.player_role_id !== originalData.value.player_role_id
  const countryChanged = form.value.country_id !== originalData.value.country_id || form.value.nationality !== originalData.value.nationality
  const imageChanged = form.value.image !== null
  const removeImageChanged = form.value.remove_image

  return nameChanged || roleChanged || countryChanged || imageChanged || removeImageChanged
})

function onFileSelected(file) {
  if (!form.value) return
  form.value.image = file || null
  form.value.remove_image = false
  previewUrl.value = file ? URL.createObjectURL(file) : props.player?.image_url || null
}

function removeImage() {
  if (!form.value) return
  form.value.image = null
  form.value.remove_image = true
  previewUrl.value = null
}

async function submit() {
  if (!form.value) {
    alert('Form not initialized')
    return
  }

  progress.value = 0
  updateLoading.value = true
  formErrors.value = {}

  try {
    const formData = new FormData()
    formData.append('name', form.value.name)
    formData.append('player_role_id', form.value.player_role_id || '')
    // If a country is selected, send country_id and set nationality to country's name for convenience
    if (form.value.country_id) {
      formData.append('country_id', form.value.country_id)
      const selected = props.countries.find(c => c.id == form.value.country_id)
      if (selected) formData.append('nationality', selected.name)
    } else {
      formData.append('nationality', form.value.nationality)
    }
    if (form.value.image) {
      formData.append('image', form.value.image)
    }
    if (form.value.remove_image) {
      formData.append('remove_image', '1')
    }
    formData.append('_method', 'PUT')

    const token = document.querySelector('meta[name="csrf-token"]')?.content

    const response = await fetch(route('admin.players.update', props.player.id), {
      method: 'POST',
      headers: {
        'Accept': 'application/json',
        'X-Requested-With': 'XMLHttpRequest',
        'X-CSRF-Token': token || '',
      },
      body: formData,
    })

    if (!response.ok) {
      const errorData = await response.json().catch(() => ({}))
      if (errorData.errors) {
        formErrors.value = errorData.errors
        updateLoading.value = false
        return
      }
      const message = errorData.message || `Server error: ${response.status}`
      throw new Error(message)
    }

    // If successful (2xx status), reload the page to refresh data
    setTimeout(() => {
      window.location.reload()
    }, 500)
  } catch (error) {
    // Handle update error
    alert(`Failed to update player: ${error.message}`)
    updateLoading.value = false
  }
}
</script>

<template>
  <Head title="Edit Player" />

  <AdminLayout>
    <div class="flex justify-between items-center mb-6">
      <h1 class="text-2xl font-bold">Edit Player</h1>
      <Link
        href="/admin/players"
        class="px-4 py-2 bg-gray-700 text-white rounded-lg hover:bg-gray-900"
      >
        ⬅ Back
      </Link>
    </div>

    <form v-if="form" @submit.prevent="submit" class="space-y-4 max-w-full sm:max-w-md">
      <div>
        <label class="block text-sm font-medium mb-1">Name</label>
        <input v-model="form.name" type="text" :class="['w-full border rounded px-3 py-2', formErrors.name ? 'border-red-500' : 'border-gray-300']" />
        <p v-if="formErrors.name" class="mt-1 text-red-600 text-sm">{{ formErrors.name }}</p>
      </div>

      <div>
        <label class="block text-sm font-medium mb-1">Role</label>
        <select v-model="form.player_role_id" :class="['w-full border rounded px-3 py-2', formErrors.player_role_id ? 'border-red-500' : 'border-gray-300']">
          <option value="">Select role</option>
          <option v-for="role in props.roles" :key="role.id" :value="role.id">
            {{ role.name }}
          </option>
        </select>
        <p v-if="formErrors.player_role_id" class="mt-1 text-red-600 text-sm">{{ formErrors.player_role_id }}</p>
      </div>

      <div>
        <label class="block text-sm font-medium mb-1">Nationality</label>
        <SearchableSelect
          v-model="form.country_id"
          :options="countryOptions"
          placeholder="Select nationality"
          name="country_id"
          :isError="formErrors.country_id ? true : false"
        />
        <p v-if="formErrors.country_id" class="mt-1 text-red-600 text-sm">{{ formErrors.country_id }}</p>
        <p v-if="formErrors.nationality" class="mt-1 text-red-600 text-sm">{{ formErrors.nationality }}</p>
      </div>

      <div>
        <FileUpload label="Image" :initial-preview="previewUrl" :progress="progress" @file-changed="onFileSelected" />
        <div v-if="progress > 0" class="text-sm text-gray-500 mt-2">Uploading: {{ progress }}%</div>
        <p v-if="formErrors.image" class="mt-1 text-red-600 text-sm">{{ formErrors.image }}</p>
        <div v-if="previewUrl" class="mt-2 flex items-center gap-3">
          <img :src="previewUrl" class="h-24 w-24 object-cover rounded" />
          <button @click.prevent="removeImage" class="px-2 py-1 text-sm border rounded text-red-600">Remove image</button>
        </div>
      </div>

      <button type="submit" :disabled="!hasChanges || updateLoading" :aria-disabled="!hasChanges || updateLoading" class="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 disabled:bg-gray-400 disabled:cursor-not-allowed">
        <span v-if="updateLoading">Updating...</span>
        <span v-else>Update Player</span>
      </button>
    </form>
  </AdminLayout>
</template>
