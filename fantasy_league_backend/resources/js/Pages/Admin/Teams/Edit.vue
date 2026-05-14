<script setup>
import { Head, Link, useForm } from '@inertiajs/vue3'
import { ref, computed, onMounted } from 'vue'
import AdminLayout from '@/Layouts/AdminLayout.vue'
import FileUpload from '@/Shared/FileUpload.vue'
import SearchableSelect from '@/Components/SearchableSelect.vue'

const props = defineProps({
  team: {
    type: Object,
    default: () => ({}),
  },
  users: Array,
})

const userOptions = computed(() => {
  return (props.users || []).map((user) => ({
    id: user.id,
    label: user.name,
  }))
})

const previewUrl = ref(null)
const progress = ref(0)

const form = useForm({
  name: '',
  user_id: '',
  logo: null,
  remove_logo: false,
  _method: null,
})

onMounted(() => {
  if (props.team) {
    form.name = props.team.name || ''
    form.user_id = props.team.user_id || ''
    previewUrl.value = props.team.logo_url || null
  }
})

function onFileSelected(file) {
  form.logo = file || null
  form.remove_logo = false
  previewUrl.value = file ? URL.createObjectURL(file) : props.team?.logo_url || null
}

function removeLogo() {
  form.logo = null
  form.remove_logo = true
  previewUrl.value = null
}

function submit() {
  progress.value = 0
  // If uploading a file, POST with _method=PUT to ensure multipart files are handled reliably by PHP
  if (form.logo) {
    form._method = 'PUT'
    form.post(route('admin.teams.update', props.team.id), {
      forceFormData: true,
      onProgress: (e) => { if (e.total) progress.value = Math.round((e.loaded / e.total) * 100) },
      onSuccess: () => { progress.value = 0 },
      onError: () => { progress.value = 0 }
    })
  } else {
    form.submit('put', route('admin.teams.update', props.team.id), {
      forceFormData: true,
      onProgress: (e) => { if (e.total) progress.value = Math.round((e.loaded / e.total) * 100) },
      onSuccess: () => { progress.value = 0 },
      onError: () => { progress.value = 0 }
    })
  }
}
</script>

<template>
  <Head title="Edit Team" />

  <AdminLayout>
    <div class="flex justify-between items-center mb-6">
      <h1 class="text-2xl font-bold">Edit Team</h1>
      <Link
        href="/admin/teams"
        class="px-4 py-2 bg-gray-700 text-white rounded-lg hover:bg-gray-900"
      >
        ⬅ Back
      </Link>
    </div>

    <form @submit.prevent="submit" class="space-y-4 max-w-full sm:max-w-md">
      <div>
        <label class="block text-sm font-medium mb-1">Team Name</label>
        <input v-model="form.name" type="text" :class="['w-full border rounded px-3 py-2', form.errors.name ? 'border-red-500' : 'border-gray-300']" />
        <p v-if="form.errors.name" class="mt-1 text-red-600 text-sm">{{ form.errors.name }}</p>
      </div>

      <div>
        <label class="block text-sm font-medium mb-1">Owner (Optional)</label>
        <SearchableSelect
          v-model="form.user_id"
          :options="userOptions"
          placeholder="Search owner by name..."
          name="user_id"
        />
      </div>

      <div>
        <FileUpload label="Logo" :initial-preview="previewUrl" :progress="progress" @file-changed="onFileSelected" />
        <div v-if="progress > 0" class="text-sm text-gray-500 mt-2">Uploading: {{ progress }}%</div>
        <p v-if="form.errors.logo" class="mt-1 text-red-600 text-sm">{{ form.errors.logo }}</p>
        <div v-if="previewUrl" class="mt-2 flex items-center gap-3">
          <img :src="previewUrl" class="h-24 w-24 object-cover rounded" />
          <button @click.prevent="removeLogo" class="px-2 py-1 text-sm border rounded text-red-600">Remove logo</button>
        </div>
      </div>

      <button type="submit" :disabled="form.processing" :aria-disabled="form.processing" class="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 disabled:bg-gray-400 disabled:cursor-not-allowed">
        <span v-if="form.processing">Updating...</span>
        <span v-else>Update Team</span>
      </button>
    </form>
  </AdminLayout>
</template>
