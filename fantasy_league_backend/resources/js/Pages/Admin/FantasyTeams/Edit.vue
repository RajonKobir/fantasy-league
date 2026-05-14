<script setup>
import { Head, Link, useForm } from '@inertiajs/vue3'
import AdminLayout from '@/Layouts/AdminLayout.vue'
import SearchableSelect from '@/Components/SearchableSelect.vue'
import { ref, computed, watch } from 'vue'

const props = defineProps({
  fantasyTeam: { type: Object, required: true },
  tournaments: { type: Array, required: true, default: () => [] },
  players: { type: Array, required: true, default: () => [] },
  users: { type: Array, required: true, default: () => [] }
})

const userOptions = computed(() => {
  return (props.users || []).map((user) => ({
    id: user.id,
    label: `${user.name} (${user.email})`,
  }))
})

// Normalize incoming player_ids to an array of numbers. The DB may store this as a JSON string.
let initialPlayerIds = []
if (Array.isArray(props.fantasyTeam.player_ids)) {
  initialPlayerIds = props.fantasyTeam.player_ids.map(id => Number(id))
} else if (props.fantasyTeam.player_ids) {
  try {
    const parsed = JSON.parse(props.fantasyTeam.player_ids)
    if (Array.isArray(parsed)) initialPlayerIds = parsed.map(id => Number(id))
  } catch (e) {
    // Fallback: try to coerce simple bracket-list string like "[1,2,3]"
    const cleaned = String(props.fantasyTeam.player_ids).replace(/[^0-9,]/g, '')
    if (cleaned.length) {
      initialPlayerIds = cleaned.split(',').filter(Boolean).map(s => Number(s))
    }
  }
}

const form = useForm({
  tournament_id: Number(props.fantasyTeam.tournament_id) || null,
  user_id: Number(props.fantasyTeam.user_id) || null,
  player_ids: initialPlayerIds,
  name: props.fantasyTeam.name || '',
  captain_id: props.fantasyTeam.captain_id ? Number(props.fantasyTeam.captain_id) : null,
  vice_captain_id: props.fantasyTeam.vice_captain_id ? Number(props.fantasyTeam.vice_captain_id) : null,
  status: props.fantasyTeam.status || 'pending',
})

const errors = ref({})
const isSubmitting = ref(false)

// Watch form.user_id to ensure it stays as number, not string
watch(() => form.user_id, (newVal) => {
  if (typeof newVal === 'string' && newVal) {
    form.user_id = Number(newVal)
  }
})

const selectedTournament = computed(() => props.tournaments.find(t => t.id === parseInt(form.tournament_id)) || null)
const requiredPlayers = computed(() => selectedTournament.value?.required_players || 0)

const tournamentPlayers = computed(() => {
  if (!form.tournament_id) return []
  // Get players who have match records in this tournament (from match_player_points)
  // For now, show all players but ideally filter by those in tournament
  return props.players
})

const selectedPlayers = computed(() => {
  return tournamentPlayers.value.filter(p => form.player_ids.includes(p.id))
})

const availablePlayers = computed(() => {
  return tournamentPlayers.value.filter(p => !form.player_ids.includes(p.id))
})

const playerSearchQuery = ref('')
const filteredAvailablePlayers = computed(() => {
  if (!playerSearchQuery.value) return availablePlayers.value
  const query = playerSearchQuery.value.toLowerCase()
  return availablePlayers.value.filter(p => {
    const name = (p.name || '').toLowerCase()
    const team = (p.team || '').toLowerCase()
    const role = (p.role || '').toLowerCase()
    return name.includes(query) || team.includes(query) || role.includes(query)
  })
})

function addPlayer(id) {
  if (!form.player_ids.includes(id) && form.player_ids.length < requiredPlayers.value) {
    form.player_ids = [...form.player_ids, id]
    playerSearchQuery.value = ''
  }
}

function removePlayer(id) {
  form.player_ids = form.player_ids.filter(pid => pid !== id)
}

function submit() {
  errors.value = {}
  isSubmitting.value = true

  // Validate tournament
  if (!form.tournament_id) {
    errors.value.tournament_id = 'Please select a tournament'
    isSubmitting.value = false
    return
  }

  // Validate user
  if (!form.user_id) {
    errors.value.user_id = 'Please select a user'
    isSubmitting.value = false
    return
  }

  // Validate captain
  if (!form.captain_id) {
    errors.value.captain_id = 'Please select a captain'
    isSubmitting.value = false
    return
  }

  // Validate vice-captain
  if (!form.vice_captain_id) {
    errors.value.vice_captain_id = 'Please select a vice-captain'
    isSubmitting.value = false
    return
  }

  // Validate number of players
  const requiredCount = requiredPlayers.value
  if (form.player_ids.length !== requiredCount) {
    errors.value.player_ids = 'Please select exactly ' + requiredCount + ' players (currently ' + form.player_ids.length + ')'
    isSubmitting.value = false
    return
  }

  // Convert Proxy objects to plain values
  const tournamentId = Number(form.tournament_id) || null
  const userId = Number(form.user_id) || null
  const playerIds = Array.isArray(form.player_ids) ? [...form.player_ids] : []
  const captainId = Number(form.captain_id) || null
  const viceCaptainId = Number(form.vice_captain_id) || null

  // Update form with converted values
  form.tournament_id = tournamentId
  form.user_id = userId
  form.player_ids = playerIds
  form.captain_id = captainId
  form.vice_captain_id = viceCaptainId

  // Ensure captain is selected and is one of the selected players
  if (captainId === null) {
    errors.value.captain_id = 'Please select a captain'
    isSubmitting.value = false
    return
  }
  if (!playerIds.includes(captainId)) {
    errors.value.captain_id = 'Captain must be one of the selected players'
    isSubmitting.value = false
    return
  }

  // Ensure vice-captain is selected and is one of the selected players
  if (viceCaptainId === null) {
    errors.value.vice_captain_id = 'Please select a vice-captain'
    isSubmitting.value = false
    return
  }
  if (!playerIds.includes(viceCaptainId)) {
    errors.value.vice_captain_id = 'Vice-captain must be one of the selected players'
    isSubmitting.value = false
    return
  }

  // Submit form (use PUT for update)
  form.put(route('admin.fantasy-teams.update', props.fantasyTeam.id), {
    onSuccess: () => { isSubmitting.value = false },
    onError: () => { isSubmitting.value = false },
    onFinish: () => { isSubmitting.value = false },
  })
}
</script>

<template>
  <Head :title="`Edit ${props.fantasyTeam.name}`" />

  <AdminLayout>
    <div class="max-w-4xl mx-auto py-8">
      <!-- Breadcrumb -->
      <div class="mb-6">
        <Link href="/admin/fantasy-teams" class="text-blue-600 hover:underline">
          ← Fantasy Teams
        </Link>
      </div>

      <!-- Card Header -->
      <div class="bg-white shadow rounded-lg p-6 mb-6">
        <h1 class="text-3xl font-bold text-gray-900 mb-2">Edit Fantasy Team</h1>
        <p class="text-gray-600">Update team details, players, and leadership</p>
      </div>

      <!-- Form Card -->
      <div class="bg-white shadow rounded-lg p-6">
        <form @submit.prevent="submit" class="space-y-6">
          <!-- Tournament -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">
              Tournament <span class="text-red-500">*</span>
            </label>
            <select v-model.number="form.tournament_id" :class="[
              'w-full px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500',
              errors.tournament_id ? 'border-red-500' : 'border-gray-300',
            ]">
              <option :value="null">Select a tournament</option>
              <option v-for="t in props.tournaments" :key="t.id" :value="t.id">{{ t.name }}</option>
            </select>
            <p v-if="errors.tournament_id" class="mt-2 text-sm text-red-600">{{ errors.tournament_id }}</p>
          </div>

          <!-- User -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">
              User <span class="text-red-500">*</span>
            </label>
            <SearchableSelect
              v-model="form.user_id"
              :options="userOptions"
              placeholder="Search users by name or email..."
              name="user_id"
              :is-error="!!errors.user_id"
            />
            <p v-if="errors.user_id" class="mt-2 text-sm text-red-600">{{ errors.user_id }}</p>
          </div>

          <!-- Team Name -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">Team Name</label>
            <input v-model="form.name" type="text" placeholder="e.g., Dream XI" class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500" />
          </div>

          <!-- Select Players -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">
              Select {{ requiredPlayers }} Players <span class="text-red-500">*</span>
            </label>
            <div class="text-sm text-gray-600 mb-4">Selected: <span class="font-bold">{{ form.player_ids.length }}/{{ requiredPlayers }}</span></div>

            <!-- Add Player Search -->
            <div v-if="form.player_ids.length < requiredPlayers" class="mb-4 relative">
              <input
                v-model="playerSearchQuery"
                type="text"
                placeholder="Search and add player by name, team, or role..."
                class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
              <!-- Dropdown suggestions -->
              <div v-if="playerSearchQuery && filteredAvailablePlayers.length > 0" class="absolute top-full left-0 right-0 bg-white border border-gray-300 rounded-lg mt-1 shadow-lg z-10 max-h-64 overflow-y-auto">
                <div
                  v-for="p in filteredAvailablePlayers"
                  :key="p.id"
                  class="px-4 py-3 hover:bg-blue-50 cursor-pointer border-b last:border-b-0 transition"
                  @click="addPlayer(p.id)"
                >
                  <div class="font-medium text-sm">{{ p.name }}</div>
                  <div class="text-xs text-gray-500">{{ p.team }} • {{ p.role }}</div>
                </div>
              </div>
              <div v-else-if="playerSearchQuery && filteredAvailablePlayers.length === 0" class="absolute top-full left-0 right-0 bg-white border border-gray-300 rounded-lg mt-1 shadow-lg px-4 py-3 text-sm text-gray-600 z-10">
                No players found matching your search
              </div>
            </div>

            <!-- Selected Players List -->
            <div v-if="selectedPlayers.length > 0" class="mb-4 space-y-2">
              <label class="block text-sm font-medium text-gray-600 mb-2">Selected Players:</label>
              <div v-for="p in selectedPlayers" :key="p.id" class="flex items-center justify-between bg-blue-50 border border-blue-200 rounded-lg px-4 py-3">
                <div>
                  <div class="font-medium text-sm">{{ p.name }}</div>
                  <div class="text-xs text-gray-600">{{ p.team }} • {{ p.role }}</div>
                </div>
                <button
                  type="button"
                  @click="removePlayer(p.id)"
                  class="px-2 py-1 text-xs text-red-600 hover:bg-red-100 rounded transition"
                >
                  Remove
                </button>
              </div>
            </div>

            <p v-if="errors.player_ids" class="text-sm text-red-600">{{ errors.player_ids }}</p>
          </div>

          <!-- Captain -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">
              Captain <span class="text-red-500">*</span>
            </label>
            <select v-model.number="form.captain_id" :class="[
              'w-full px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500',
              errors.captain_id ? 'border-red-500' : 'border-gray-300',
            ]">
              <option :value="null">Select captain from selected players</option>
              <option v-for="p in selectedPlayers" :key="p.id" :value="p.id">
                {{ p.name }} ({{ p.team }})
              </option>
            </select>
            <p v-if="errors.captain_id" class="mt-2 text-sm text-red-600">{{ errors.captain_id }}</p>
          </div>

          <!-- Vice-Captain -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">
              Vice-Captain <span class="text-red-500">*</span>
            </label>
            <select v-model.number="form.vice_captain_id" :class="[
              'w-full px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500',
              errors.vice_captain_id ? 'border-red-500' : 'border-gray-300',
            ]">
              <option :value="null">Select vice-captain from selected players</option>
              <option v-for="p in selectedPlayers" :key="p.id" :value="p.id">
                {{ p.name }} ({{ p.team }})
              </option>
            </select>
            <p v-if="errors.vice_captain_id" class="mt-2 text-sm text-red-600">{{ errors.vice_captain_id }}</p>
          </div>

          <!-- Status -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">
              Approval Status
            </label>
            <select v-model="form.status" class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500">
              <option value="pending">⏳ Pending - Awaiting Admin Review</option>
              <option value="approved">✓ Approved - Team Accepted</option>
              <option value="rejected">✗ Rejected - Team Not Approved</option>
            </select>
            <p class="mt-2 text-xs text-gray-500">Change team approval status. Pending means user must wait for admin approval.</p>
          </div>

          <!-- Form Actions -->
          <div class="flex gap-3 pt-6 border-t">
            <button
              type="submit"
              :disabled="isSubmitting"
              class="flex-1 px-6 py-2 btn-primary"
            >
              {{ isSubmitting ? 'Saving...' : 'Update Fantasy Team' }}
            </button>
            <Link
              href="/admin/fantasy-teams"
              class="flex-1 px-6 py-2 bg-gray-200 text-gray-700 rounded-lg font-medium hover:bg-gray-300 text-center transition"
            >
              Cancel
            </Link>
          </div>
        </form>
      </div>
    </div>
  </AdminLayout>
</template>
