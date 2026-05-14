<script setup>
import { Head, Link, useForm } from '@inertiajs/vue3'
import { ref } from 'vue'
import AdminLayout from '@/Layouts/AdminLayout.vue'
import FileUpload from '@/Shared/FileUpload.vue'

const previewUrl = ref(null)
const progress = ref(0)
const form = useForm({ name:'', description:'', start_at:'', end_at:'', entry_fee:'', required_players: 11, captain_multiplier: 2.0, vice_captain_multiplier: 2.0, refund_percentage: 100.0, status: 'active', logo: null })

function onFileSelected(file) { const f = file; form.logo = f || null; previewUrl.value = f ? URL.createObjectURL(f) : null }

function submit() {
  progress.value = 0
  form.post(route('admin.tournaments.store'), {
    forceFormData: true,
    onProgress: (e) => { if (e.total) progress.value = Math.round((e.loaded / e.total) * 100) },
    onSuccess: () => { progress.value = 0 }
  })
}
</script>

<template>
  <Head title="Create Tournament" />
  <AdminLayout>
    <div class="flex justify-between items-center mb-6">
      <h1 class="text-2xl font-bold">Create Tournament</h1>
      <Link href="/admin/tournaments" class="px-4 py-2 bg-gray-700 text-white rounded-lg hover:bg-gray-900">⬅ Back</Link>
    </div>

    <form @submit.prevent="submit" class="space-y-4 max-w-full sm:max-w-md">
      <div>
        <label class="block text-sm font-medium mb-1">Name</label>
        <input v-model="form.name" type="text" :class="['w-full border rounded px-3 py-2', form.errors.name ? 'border-red-500' : 'border-gray-300']" />
        <p v-if="form.errors.name" class="mt-1 text-red-600 text-sm">{{ form.errors.name }}</p>
      </div>

      <div>
        <label class="block text-sm font-medium mb-1">Description</label>
        <textarea v-model="form.description" :class="['w-full border rounded px-3 py-2', form.errors.description ? 'border-red-500' : 'border-gray-300']" />
        <p v-if="form.errors.description" class="mt-1 text-red-600 text-sm">{{ form.errors.description }}</p>
      </div>

      <div>
        <label class="block text-sm font-medium mb-1">Start</label>
        <input v-model="form.start_at" type="datetime-local" :class="['w-full border rounded px-3 py-2', form.errors.start_at ? 'border-red-500' : 'border-gray-300']" />
        <p v-if="form.errors.start_at" class="mt-1 text-red-600 text-sm">{{ form.errors.start_at }}</p>
      </div>

      <div>
        <label class="block text-sm font-medium mb-1">End</label>
        <input v-model="form.end_at" type="datetime-local" :class="['w-full border rounded px-3 py-2', form.errors.end_at ? 'border-red-500' : 'border-gray-300']" />
        <p v-if="form.errors.end_at" class="mt-1 text-red-600 text-sm">{{ form.errors.end_at }}</p>
      </div>

      <div>
        <label class="block text-sm font-medium mb-1">Entry Fee</label>
        <input v-model="form.entry_fee" type="number" step="0.01" :class="['w-full border rounded px-3 py-2', form.errors.entry_fee ? 'border-red-500' : 'border-gray-300']" />
        <p v-if="form.errors.entry_fee" class="mt-1 text-red-600 text-sm">{{ form.errors.entry_fee }}</p>
      </div>

      <div>
        <label class="block text-sm font-medium mb-1">Required Players</label>
        <input v-model="form.required_players" type="number" min="1" max="100" :class="['w-full border rounded px-3 py-2', form.errors.required_players ? 'border-red-500' : 'border-gray-300']" />
        <p v-if="form.errors.required_players" class="mt-1 text-red-600 text-sm">{{ form.errors.required_players }}</p>
        <p v-else class="text-xs text-gray-500 mt-1">Number of players required in a team for this tournament</p>
      </div>

      <div>
        <label class="block text-sm font-medium mb-1">Captain Multiplier</label>
        <input v-model="form.captain_multiplier" type="number" step="0.1" min="1" :class="['w-full border rounded px-3 py-2', form.errors.captain_multiplier ? 'border-red-500' : 'border-gray-300']" />
        <p v-if="form.errors.captain_multiplier" class="mt-1 text-red-600 text-sm">{{ form.errors.captain_multiplier }}</p>
        <p v-else class="text-xs text-gray-500 mt-1">Multiplier applied to captain's points (default 2.0)</p>
      </div>

      <div>
        <label class="block text-sm font-medium mb-1">Vice Captain Multiplier</label>
        <input v-model="form.vice_captain_multiplier" type="number" step="0.1" min="1" :class="['w-full border rounded px-3 py-2', form.errors.vice_captain_multiplier ? 'border-red-500' : 'border-gray-300']" />
        <p v-if="form.errors.vice_captain_multiplier" class="mt-1 text-red-600 text-sm">{{ form.errors.vice_captain_multiplier }}</p>
        <p v-else class="text-xs text-gray-500 mt-1">Multiplier applied to vice-captain's points (default 2.0)</p>
      </div>

      <div>
        <label class="block text-sm font-medium mb-1">Refund Percentage (%)</label>
        <input v-model="form.refund_percentage" type="number" step="0.01" min="0" max="100" :class="['w-full border rounded px-3 py-2', form.errors.refund_percentage ? 'border-red-500' : 'border-gray-300']" />
        <p v-if="form.errors.refund_percentage" class="mt-1 text-red-600 text-sm">{{ form.errors.refund_percentage }}</p>
        <p v-else class="text-xs text-gray-500 mt-1">Percentage of entry fee refunded when team is canceled (0-100, default 100)</p>
      </div>

      <div>
        <label class="block text-sm font-medium mb-1">Status</label>
        <select v-model="form.status" :class="['w-full border rounded px-3 py-2', form.errors.status ? 'border-red-500' : 'border-gray-300']">
          <option value="upcoming">Upcoming</option>
          <option value="running">Running</option>
          <option value="active">Active</option>
          <option value="stopped">Stopped</option>
          <option value="canceled">Canceled</option>
        </select>
        <p v-if="form.errors.status" class="mt-1 text-red-600 text-sm">{{ form.errors.status }}</p>
      </div>

      <div>
        <FileUpload label="Logo" :initial-preview="previewUrl" :progress="progress" @file-changed="onFileSelected" />
        <p v-if="form.errors.logo" class="mt-1 text-red-600 text-sm">{{ form.errors.logo }}</p>
      </div>

      <button type="submit" :disabled="form.processing" :aria-disabled="form.processing" class="px-4 py-2 btn-primary">
        <span v-if="form.processing">Creating...</span>
        <span v-else>Create</span>
      </button>
    </form>
  </AdminLayout>
</template>
