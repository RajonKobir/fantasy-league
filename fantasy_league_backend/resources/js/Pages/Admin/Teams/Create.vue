<script setup>
import { Head, Link, useForm } from '@inertiajs/vue3'
import { ref, computed } from 'vue'
import AdminLayout from '@/Layouts/AdminLayout.vue'
import FileUpload from '@/Shared/FileUpload.vue'
import SearchableSelect from '@/Components/SearchableSelect.vue'
import { usePage } from '@inertiajs/vue3'

const page = usePage()

const previewUrl = ref(null)
const progress = ref(0)

const form = useForm({
  name: '',
  user_id: '', // select owner (optional for system teams)
  logo: null,
})

function onFileSelected(file) {
  if (file) {
    form.logo = file
    previewUrl.value = URL.createObjectURL(file)
  } else {
    form.logo = null
    previewUrl.value = null
  }
}

const userOptions = computed(() => {
  return (page.props.users || []).map((user) => ({
    id: user.id,
    label: user.name,
  }))
})

function submit() {
  progress.value = 0
  form.post(route('admin.teams.store'), {
    forceFormData: true,
    onProgress: (e) => { if (e.total) progress.value = Math.round((e.loaded / e.total) * 100) },
    onSuccess: () => { progress.value = 0 }
  })
}
</script>

<template>
  <Head title="Create Team" />

  <AdminLayout>
    <div class="flex justify-between items-center mb-6">
      <h1 class="text-2xl font-bold">Create Team</h1>
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
        <div v-if="form.errors.name" class="text-red-600 text-sm mt-1">{{ form.errors.name }}</div>
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
        <div v-if="form.errors.logo" class="text-red-600 text-sm mt-2">{{ form.errors.logo }}</div>
        <div v-if="previewUrl" class="mt-2 flex items-center gap-3">
          <img :src="previewUrl" class="h-24 w-24 object-cover rounded" />
        </div>
      </div>

      <button type="submit" :disabled="form.processing" :aria-disabled="form.processing" class="px-4 py-2 btn-primary">
        <span v-if="form.processing">Saving...</span>
        <span v-else>Save Team</span>
      </button>
    </form>
  </AdminLayout>
</template>
