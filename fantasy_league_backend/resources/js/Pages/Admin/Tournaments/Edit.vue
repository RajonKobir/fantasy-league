<script setup>
import { Head, Link, router } from '@inertiajs/vue3'
import { ref, computed, onMounted } from 'vue'
import AdminLayout from '@/Layouts/AdminLayout.vue'
import SearchableSelect from '@/Components/SearchableSelect.vue'
import FileUpload from '@/Shared/FileUpload.vue'

const props = defineProps({
  tournament: {
    type: Object,
    default: () => ({}),
  },
  teams: Array,
  players: Array
})

const previewUrl = ref(null)
const progress = ref(0)
const updateLoading = ref(false)
const formErrors = ref({})

// Initialize form with safe defaults
const form = ref({
  name: '',
  description: '',
  start_at: '',
  end_at: '',
  entry_fee: '',
  required_players: 11,
  captain_multiplier: 2.0,
  vice_captain_multiplier: 2.0,
  refund_percentage: 100.0,
  status: 'active',
  logo: null,
  remove_logo: false,
})

// Track original data for change detection
const originalData = ref({
  name: '',
  description: '',
  start_at: '',
  end_at: '',
  entry_fee: '',
  required_players: 11,
  captain_multiplier: 2.0,
  vice_captain_multiplier: 2.0,
  refund_percentage: 100.0,
  status: 'active',
})

// Helper function to convert datetime string to datetime-local format
function formatDateTime(dateStr) {
  if (!dateStr) return ''
  // Handle both formats: "2026-02-02T12:00:00" and "2026-02-02 12:00:00"
  return dateStr.replace(' ', 'T').substring(0, 16)
}

// Initialize on mount
onMounted(() => {
  if (props.tournament) {
    form.value = {
      name: props.tournament.name || '',
      description: props.tournament.description || '',
      start_at: formatDateTime(props.tournament.start_at) || '',
      end_at: formatDateTime(props.tournament.end_at) || '',
      entry_fee: props.tournament.entry_fee || '',
      required_players: props.tournament.required_players || 11,
      captain_multiplier: props.tournament.captain_multiplier ?? 2.0,
      vice_captain_multiplier: props.tournament.vice_captain_multiplier ?? 2.0,
      refund_percentage: props.tournament.refund_percentage ?? 100.0,
      status: props.tournament.status || 'active',
      logo: null,
      remove_logo: false,
    }
    originalData.value = {
      name: props.tournament.name || '',
      description: props.tournament.description || '',
      start_at: formatDateTime(props.tournament.start_at) || '',
      end_at: formatDateTime(props.tournament.end_at) || '',
      entry_fee: props.tournament.entry_fee || '',
      required_players: props.tournament.required_players || 11,
      captain_multiplier: props.tournament.captain_multiplier ?? 2.0,
      vice_captain_multiplier: props.tournament.vice_captain_multiplier ?? 2.0,
      refund_percentage: props.tournament.refund_percentage ?? 100.0,
      status: props.tournament.status || 'active',
    }
    previewUrl.value = props.tournament.logo_url || null
  }
})

// Check if form has any changes
const hasChanges = computed(() => {
  const nameChanged = form.value.name !== originalData.value.name
  const descChanged = form.value.description !== originalData.value.description
  const startChanged = form.value.start_at !== originalData.value.start_at
  const endChanged = form.value.end_at !== originalData.value.end_at
  const feeChanged = form.value.entry_fee !== originalData.value.entry_fee
  const playersChanged = form.value.required_players !== originalData.value.required_players
  const captainChanged = form.value.captain_multiplier !== originalData.value.captain_multiplier
  const viceChanged = form.value.vice_captain_multiplier !== originalData.value.vice_captain_multiplier
  const refundChanged = form.value.refund_percentage !== originalData.value.refund_percentage
  const statusChanged = form.value.status !== originalData.value.status
  const logoChanged = form.value.logo !== null
  const removeLogoChanged = form.value.remove_logo

  return nameChanged || descChanged || startChanged || endChanged || feeChanged || playersChanged || statusChanged || logoChanged || removeLogoChanged || captainChanged || viceChanged || refundChanged
})

// available teams for dropdown (those not already in tournament)
const availableTeamOptions = computed(() => {
  return (props.teams || [])
    .filter(t => !t.is_assigned)
    .map(t => ({
      id: t.id,
      label: t.name
    }))
})

function onFileSelected(file) {
  form.value.logo = file || null
  form.value.remove_logo = false
  previewUrl.value = file ? URL.createObjectURL(file) : props.tournament?.logo_url || null
}

function removeLogo() {
  form.value.logo = null
  form.value.remove_logo = true
  previewUrl.value = null
}

async function submit() {
  progress.value = 0
  updateLoading.value = true
  formErrors.value = {}

  try {
    const formData = new FormData()
    formData.append('name', form.value.name)
    formData.append('description', form.value.description)
    formData.append('start_at', form.value.start_at)
    formData.append('end_at', form.value.end_at)
    formData.append('entry_fee', form.value.entry_fee)
    formData.append('required_players', form.value.required_players)
    formData.append('captain_multiplier', form.value.captain_multiplier)
    formData.append('vice_captain_multiplier', form.value.vice_captain_multiplier)
    formData.append('refund_percentage', form.value.refund_percentage)
    formData.append('status', form.value.status)
    if (form.value.logo) {
      formData.append('logo', form.value.logo)
    }
    if (form.value.remove_logo) {
      formData.append('remove_logo', '1')
    }
    formData.append('_method', 'PUT')

    // Add CSRF token to FormData
    const token = document.querySelector('meta[name="csrf-token"]')?.content
    if (token) {
      formData.append('_token', token)
    }

    const response = await fetch(route('admin.tournaments.update', props.tournament.id), {
      method: 'POST',
      headers: {
        'Accept': 'application/json',
        'X-Requested-With': 'XMLHttpRequest',
      },
      body: formData,
    })

    if (!response.ok) {
      const errorData = await response.json().catch(() => ({}))
      if (errorData.errors) {
        formErrors.value = errorData.errors
      } else {
        alert(errorData.message || 'Failed to update tournament')
      }
      updateLoading.value = false
      return
    }

    // If successful (2xx status), reload the page to refresh data
    setTimeout(() => {
      window.location.reload()
    }, 500)
  } catch (error) {
    // Handle update error
    alert('Failed to update tournament: ' + error.message)
    updateLoading.value = false
  }
}

// team assign form
const teamForm = ref({ team_id: '' })
function assignTeam() {
  router.post(route('admin.tournaments.assignTeam', props.tournament.id), { team_id: teamForm.value.team_id })
}

function removeTeam(teamId) {
  if (!confirm('Remove team from tournament?')) return
  router.delete(route('admin.tournaments.removeTeam', [props.tournament.id, teamId]))
}
</script>

<template>
  <Head :title="`Edit: ${props.tournament?.name || 'Tournament'}`" />
  <AdminLayout>
    <div class="flex justify-between items-center mb-6">
      <h1 class="text-2xl font-bold">Edit Tournament - {{ props.tournament?.name }}</h1>
      <Link href="/admin/tournaments" class="px-4 py-2 bg-gray-700 text-white rounded-lg hover:bg-gray-900">⬅ Back</Link>
    </div>

    <form @submit.prevent="submit" class="space-y-4 max-w-full sm:max-w-md">
      <div>
        <label class="block text-sm font-medium mb-1">Name</label>
        <input v-model="form.name" type="text" :class="['w-full border rounded px-3 py-2', formErrors.name ? 'border-red-500' : 'border-gray-300']" />
        <p v-if="formErrors.name" class="mt-1 text-red-600 text-sm">{{ formErrors.name }}</p>
      </div>

      <div>
        <label class="block text-sm font-medium mb-1">Description</label>
        <textarea v-model="form.description" :class="['w-full border rounded px-3 py-2', formErrors.description ? 'border-red-500' : 'border-gray-300']" />
        <p v-if="formErrors.description" class="mt-1 text-red-600 text-sm">{{ formErrors.description }}</p>
      </div>

      <div>
        <label class="block text-sm font-medium mb-1">Start</label>
        <input v-model="form.start_at" type="datetime-local" :class="['w-full border rounded px-3 py-2', formErrors.start_at ? 'border-red-500' : 'border-gray-300']" />
        <p v-if="formErrors.start_at" class="mt-1 text-red-600 text-sm">{{ formErrors.start_at }}</p>
      </div>

      <div>
        <label class="block text-sm font-medium mb-1">End</label>
        <input v-model="form.end_at" type="datetime-local" :class="['w-full border rounded px-3 py-2', formErrors.end_at ? 'border-red-500' : 'border-gray-300']" />
        <p v-if="formErrors.end_at" class="mt-1 text-red-600 text-sm">{{ formErrors.end_at }}</p>
      </div>

      <div>
        <label class="block text-sm font-medium mb-1">Entry Fee</label>
        <input v-model="form.entry_fee" type="number" step="0.01" :class="['w-full border rounded px-3 py-2', formErrors.entry_fee ? 'border-red-500' : 'border-gray-300']" />
        <p v-if="formErrors.entry_fee" class="mt-1 text-red-600 text-sm">{{ formErrors.entry_fee }}</p>
      </div>

      <div>
        <label class="block text-sm font-medium mb-1">Required Players</label>
        <input v-model="form.required_players" type="number" min="1" max="100" :class="['w-full border rounded px-3 py-2', formErrors.required_players ? 'border-red-500' : 'border-gray-300']" />
        <p v-if="formErrors.required_players" class="mt-1 text-red-600 text-sm">{{ formErrors.required_players }}</p>
        <p v-else class="text-xs text-gray-500 mt-1">Number of players required in a team for this tournament</p>
      </div>

      <div>
        <label class="block text-sm font-medium mb-1">Captain Multiplier</label>
        <input v-model="form.captain_multiplier" type="number" step="0.1" min="1" :class="['w-full border rounded px-3 py-2', formErrors.captain_multiplier ? 'border-red-500' : 'border-gray-300']" />
        <p v-if="formErrors.captain_multiplier" class="mt-1 text-red-600 text-sm">{{ formErrors.captain_multiplier }}</p>
        <p v-else class="text-xs text-gray-500 mt-1">Multiplier applied to captain's points (default 2.0)</p>
      </div>

      <div>
        <label class="block text-sm font-medium mb-1">Vice Captain Multiplier</label>
        <input v-model="form.vice_captain_multiplier" type="number" step="0.1" min="1" :class="['w-full border rounded px-3 py-2', formErrors.vice_captain_multiplier ? 'border-red-500' : 'border-gray-300']" />
        <p v-if="formErrors.vice_captain_multiplier" class="mt-1 text-red-600 text-sm">{{ formErrors.vice_captain_multiplier }}</p>
        <p v-else class="text-xs text-gray-500 mt-1">Multiplier applied to vice-captain's points (default 2.0)</p>
      </div>

      <div>
        <label class="block text-sm font-medium mb-1">Refund Percentage (%)</label>
        <input v-model="form.refund_percentage" type="number" step="0.01" min="0" max="100" :class="['w-full border rounded px-3 py-2', formErrors.refund_percentage ? 'border-red-500' : 'border-gray-300']" />
        <p v-if="formErrors.refund_percentage" class="mt-1 text-red-600 text-sm">{{ formErrors.refund_percentage }}</p>
        <p v-else class="text-xs text-gray-500 mt-1">Percentage of entry fee refunded when team is canceled (0-100, default 100)</p>
      </div>

      <div>
        <label class="block text-sm font-medium mb-1">Status</label>
        <select v-model="form.status" :class="['w-full border rounded px-3 py-2', formErrors.status ? 'border-red-500' : 'border-gray-300']">
          <option value="upcoming">Upcoming</option>
          <option value="running">Running</option>
          <option value="active">Active</option>
          <option value="stopped">Stopped</option>
          <option value="canceled">Canceled</option>
        </select>
        <p v-if="formErrors.status" class="mt-1 text-red-600 text-sm">{{ formErrors.status }}</p>
      </div>

      <div>
        <FileUpload label="Logo" :initial-preview="previewUrl" :progress="progress" @file-changed="onFileSelected" />
        <p v-if="formErrors.logo" class="mt-1 text-red-600 text-sm">{{ formErrors.logo }}</p>
        <div v-if="previewUrl" class="mt-2 flex items-center gap-3">
          <img :src="previewUrl" class="h-24 w-24 object-cover rounded" />
          <button @click.prevent="removeLogo" class="px-2 py-1 text-sm border rounded text-red-600">Remove logo</button>
        </div>
      </div>

      <button type="submit" :disabled="!hasChanges || updateLoading" :aria-disabled="!hasChanges || updateLoading" class="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 disabled:bg-gray-400 disabled:cursor-not-allowed">
        <span v-if="updateLoading">Saving...</span>
        <span v-else>Save</span>
      </button>
    </form>

    <hr class="my-6" />

    <h2 class="text-xl font-semibold mb-2">Teams in Tournament</h2>
    <div class="space-y-2">
      <div v-for="t in props.teams?.filter(x => x.is_assigned)" :key="t.id" class="flex items-center justify-between border p-2">
        <div>{{ t.name }}</div>
        <div>
          <Link :href="route('admin.teams.selections.edit', t.id)" class="mr-3 text-blue-600">Manage Players</Link>
          <button @click.prevent="removeTeam(t.id)" class="text-red-600">Remove</button>
        </div>
      </div>

      <form @submit.prevent="assignTeam" class="flex gap-2 mt-2">
        <SearchableSelect
          v-model="teamForm.team_id"
          :options="availableTeamOptions"
          placeholder="Search teams to add..."
          name="team_id"
        />
        <button type="submit" class="px-3 py-2 btn-success">Add</button>
      </form>
    </div>

  </AdminLayout>
</template>
