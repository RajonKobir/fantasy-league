<script setup>
import { Head, Link } from '@inertiajs/vue3'
import { ref, computed } from 'vue'
import AdminLayout from '@/Layouts/AdminLayout.vue'
import FileUpload from '@/Shared/FileUpload.vue'
import SearchableSelect from '@/Components/SearchableSelect.vue'

const props = defineProps({
  roles: Array,
  countries: Array,
})

const previewUrl = ref(null)
const progress = ref(0)
const loading = ref(false)
const errors = ref({})

const form = ref({
  name: '',
  player_role_id: '',
  nationality: '',
  country_id: '',
  image: null,
})

const countryOptions = computed(() => (props.countries || []).map(c => ({ id: c.id, label: c.name })))

function onFileSelected(file) {
  form.value.image = file || null
  previewUrl.value = file ? URL.createObjectURL(file) : null
}

function submit() {
  progress.value = 0
  loading.value = true
  errors.value = {}

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
    const token = document.querySelector('meta[name="csrf-token"]')?.content

    const xhr = new XMLHttpRequest()

    xhr.upload.addEventListener('progress', (e) => {
      if (e.total) progress.value = Math.round((e.loaded / e.total) * 100)
    })

    xhr.addEventListener('load', () => {
      if (xhr.status === 200 || xhr.status === 201) {
        window.location.href = route('admin.players.index')
      } else if (xhr.status === 422) {
        try {
          const response = JSON.parse(xhr.responseText)
          if (response.errors) {
            errors.value = response.errors
          }
        } catch (e) {
          alert('Failed to create player. Please try again.')
        }
        loading.value = false
      } else {
        alert('Failed to create player. Please try again.')
        loading.value = false
      }
    })

    xhr.addEventListener('error', () => {
      alert('Error uploading player. Please try again.')
      loading.value = false
    })

    xhr.open('POST', route('admin.players.store'))
    xhr.setRequestHeader('Accept', 'application/json')
    xhr.setRequestHeader('X-Requested-With', 'XMLHttpRequest')
    xhr.setRequestHeader('X-CSRF-Token', token || '')
    xhr.send(formData)
  } catch (error) {
    alert('Error: ' + error.message)
    loading.value = false
  }
}
</script>

<template>
  <Head title="Create Player" />

  <AdminLayout>
    <div class="flex justify-between items-center mb-6">
      <h1 class="text-2xl font-bold">Create Player</h1>
      <Link
        href="/admin/players"
        class="px-4 py-2 bg-gray-700 text-white rounded-lg hover:bg-gray-900"
      >
        ⬅ Back
      </Link>
    </div>

    <form @submit.prevent="submit" class="space-y-4 max-w-full sm:max-w-md">
      <div>
        <label class="block text-sm font-medium mb-1">Name</label>
        <input v-model="form.name" type="text" :class="['w-full border rounded px-3 py-2', errors.name ? 'border-red-500' : 'border-gray-300']" />
        <p v-if="errors.name" class="mt-1 text-red-600 text-sm">{{ errors.name }}</p>
      </div>

      <div>
        <label class="block text-sm font-medium mb-1">Role</label>
        <select v-model="form.player_role_id" :class="['w-full border rounded px-3 py-2', errors.player_role_id ? 'border-red-500' : 'border-gray-300']">
          <option value="">Select role</option>
          <option v-for="role in props.roles" :key="role.id" :value="role.id">
            {{ role.name }}
          </option>
        </select>
        <p v-if="errors.player_role_id" class="mt-1 text-red-600 text-sm">{{ errors.player_role_id }}</p>
      </div>

        <div>
        <label class="block text-sm font-medium mb-1">Nationality</label>
        <SearchableSelect
          v-model="form.country_id"
          :options="countryOptions"
          placeholder="Select nationality"
          name="country_id"
          :isError="errors.country_id ? true : false"
        />
        <p v-if="errors.country_id" class="mt-1 text-red-600 text-sm">{{ errors.country_id }}</p>
        <p v-if="errors.nationality" class="mt-1 text-red-600 text-sm">{{ errors.nationality }}</p>
      </div>

      <div>
        <FileUpload label="Image" :initial-preview="previewUrl" :progress="progress" @file-changed="onFileSelected" />
        <p v-if="errors.image" class="mt-1 text-red-600 text-sm">{{ errors.image }}</p>
      </div>

      <button type="submit" :disabled="loading" :aria-disabled="loading" class="px-4 py-2 btn-primary">
        <span v-if="loading">Saving...</span>
        <span v-else>Save Player</span>
      </button>
    </form>
  </AdminLayout>
</template>
