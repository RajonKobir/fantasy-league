<script setup>
import { Head, Link, useForm } from '@inertiajs/vue3'
import { ref, computed, onMounted } from 'vue'
import AdminLayout from '@/Layouts/AdminLayout.vue'

const props = defineProps({ team: Object, players: Array, selections: Array })

// initialize form with current player ids and captain/vice
// Normalize IDs to numbers to avoid type-mismatch when comparing with players array
const selectedIds = ref(props.selections.map(s => Number(s.player_id)))
const _capt = props.selections.find(s => s.captain)
const _vice = props.selections.find(s => s.vice_captain)
const captainId = ref(_capt ? Number(_capt.player_id) : null)
const viceCaptainId = ref(_vice ? Number(_vice.player_id) : null)

const form = useForm({ player_ids: selectedIds.value, captain_id: captainId.value, vice_captain_id: viceCaptainId.value })
const showConfirm = ref(false)

// Searchable dropdown state
const playerSearch = ref('')
const dropdownOpen = ref(false)

const filteredPlayers = computed(() => {
  // First, exclude already selected players
  const available = props.players.filter(p => !selectedIds.value.includes(p.id))

  if (!playerSearch.value) return available

  const search = playerSearch.value.toLowerCase()
  return available.filter(p =>
    p.name?.toLowerCase().includes(search) ||
    p.position?.toLowerCase().includes(search)
  )
})

const selectedCount = computed(() => selectedIds.value.length)
const isValid = computed(() => {
  return selectedCount.value > 0 && captainId.value && viceCaptainId.value && captainId.value !== viceCaptainId.value
})

function openConfirm() {
  // sync reactive values into form
  form.player_ids = selectedIds.value
  form.captain_id = captainId.value
  form.vice_captain_id = viceCaptainId.value

  if (!isValid.value) {
    // highlight errors client-side
    if (selectedCount.value === 0) {
      alert('Please select at least one player.')
      return
    }
    if (!captainId.value || !viceCaptainId.value) {
      alert('Please select both a Captain and a Vice-Captain.')
      return
    }
    if (captainId.value === viceCaptainId.value) {
      alert('Captain and Vice-Captain must be different.')
      return
    }
  }

  showConfirm.value = true
}

function confirmSubmit() {
  showConfirm.value = false
  form.post(route('admin.teams.selections.update', props.team.id))
}

function togglePlayerSelection(playerId) {
  const pid = Number(playerId)
  const index = selectedIds.value.indexOf(pid)
  if (index > -1) {
    selectedIds.value.splice(index, 1)
    // if removed player was captain or vice-captain, clear those selections
    if (captainId.value === pid) captainId.value = null
    if (viceCaptainId.value === pid) viceCaptainId.value = null
  } else {
    selectedIds.value.push(pid)
  }
}

function selectPlayerFromDropdown(player) {
  togglePlayerSelection(player.id)
  playerSearch.value = ''
  // Keep dropdown open so admin can continue selecting players
    dropdownOpen.value = true
}

function handleDropdownBlur() {
  setTimeout(() => {
    dropdownOpen.value = false
  }, 200)
}

onMounted(() => {
  // Component mounted, props loaded
})
</script>

<template>
  <Head :title="`Manage Players: ${team.name}`" />

  <AdminLayout>
    <div class="flex justify-between items-center mb-6">
      <h1 class="text-2xl font-bold">Manage Players for {{ team.name }}</h1>
      <Link href="/admin/teams" class="px-4 py-2 bg-gray-700 text-white rounded-lg hover:bg-gray-900">⬅ Back</Link>
    </div>

    <div class="mb-6">
      <h2 class="font-semibold mb-3">Current Selections ({{ selectedCount }})</h2>
      <div class="text-xs text-gray-500 mb-2">Total available players: {{ players.length }}</div>
      <div v-if="selectedIds.length === 0" class="text-gray-500 text-sm py-2">No players selected yet</div>
      <div v-else class="space-y-1 border rounded bg-gray-50 p-3" style="min-height: auto; max-height: none;">
        <div v-for="playerId in selectedIds" :key="playerId" class="flex items-center justify-between p-2 bg-white rounded border border-gray-200 hover:bg-gray-50">
          <div class="flex-1">
            <div class="font-medium text-sm text-gray-900">{{ players.find(p => p.id === playerId)?.name || '—' }}</div>
            <div class="text-xs text-gray-500">{{ players.find(p => p.id === playerId)?.position || 'N/A' }}</div>
            <div class="flex gap-2 mt-0.5">
              <span v-if="playerId === captainId" class="text-xs font-semibold text-blue-600 bg-blue-100 px-1.5 py-0.5 rounded">⭐ Captain</span>
              <span v-if="playerId === viceCaptainId" class="text-xs font-semibold text-purple-600 bg-purple-100 px-1.5 py-0.5 rounded">⭐ Vice-Captain</span>
            </div>
          </div>
          <button type="button" @click="togglePlayerSelection(playerId)" class="ml-2 text-red-500 hover:text-red-700 font-medium text-sm">Remove</button>
        </div>
      </div>
    </div>

    <form @submit.prevent="openConfirm" class="space-y-4 max-w-2xl">
      <div class="relative">
        <label class="block text-sm font-medium mb-1">Select Players</label>
        <input
          v-model="playerSearch"
          type="text"
          placeholder="Search by player name or position..."
          @focus="dropdownOpen = true"
          @blur="handleDropdownBlur"
          class="w-full border rounded px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500"
          :class="{ 'border-red-500': form.errors.player_ids, 'border-gray-300': !form.errors.player_ids }"
        />

        <!-- Dropdown Menu: Show if input is focused OR if there are available players to select -->
        <div v-if="dropdownOpen && filteredPlayers.length > 0" class="absolute top-full left-0 right-0 mt-1 bg-white border border-gray-300 rounded-lg shadow-lg z-10 max-h-60 overflow-y-auto">
          <div
            v-for="player in filteredPlayers"
            :key="player.id"
            @click="selectPlayerFromDropdown(player)"
            class="px-4 py-2 hover:bg-blue-50 cursor-pointer border-b border-gray-100 last:border-0 flex items-center justify-between"
          >
            <div>
              <div class="font-medium text-gray-900">{{ player.name }}</div>
              <div class="text-xs text-gray-500">{{ player.position || 'N/A' }}</div>
            </div>
            <input
              type="checkbox"
              :checked="selectedIds.includes(player.id)"
              class="ml-2"
              @click.stop
            />
          </div>
        </div>

        <!-- Empty State -->
        <div v-if="dropdownOpen && filteredPlayers.length === 0 && playerSearch" class="absolute top-full left-0 right-0 mt-1 bg-white border border-gray-300 rounded-lg shadow-lg z-10 px-4 py-3">
          <p class="text-gray-500 text-sm">No players found matching your search.</p>
        </div>

        <div class="text-sm text-gray-500 mt-1">Search and click to select players</div>
        <div v-if="form.errors.player_ids" class="text-red-500 text-sm">{{ form.errors.player_ids }}</div>
        <div v-if="selectedCount === 0" class="text-yellow-600 text-sm mt-1">Selected: {{ selectedCount }} (select at least one)</div>
        <div v-else class="text-green-600 text-sm mt-1">Selected: {{ selectedCount }} players</div>
      </div>

      <div class="flex gap-4 items-center">
        <div class="flex-1">
          <label class="block text-sm font-medium mb-1">Captain</label>
          <select v-model="captainId" class="w-full border rounded px-3 py-2">
            <option value="">Select Captain</option>
            <option v-for="id in selectedIds" :key="id" :value="id">{{ players.find(p => p.id === id)?.name }}</option>
          </select>
          <div v-if="form.errors.captain_id || (!captainId && selectedCount > 0)" class="text-yellow-600 text-sm">Please select a captain</div>
        </div>
        <div class="flex-1">
          <label class="block text-sm font-medium mb-1">Vice-Captain</label>
          <select v-model="viceCaptainId" class="w-full border rounded px-3 py-2">
            <option value="">Select Vice-Captain</option>
            <option v-for="id in selectedIds" :key="id" :value="id">{{ players.find(p => p.id === id)?.name }}</option>
          </select>
          <div v-if="form.errors.vice_captain_id || (!viceCaptainId && selectedCount > 0)" class="text-yellow-600 text-sm">Please select a vice-captain</div>
        </div>
      </div>

      <button type="submit" :disabled="!isValid" class="px-4 py-2 btn-primary">Save Selections</button>
    </form>

    <!-- Confirmation modal -->
    <div v-if="showConfirm" class="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
      <div class="bg-white rounded-lg p-6 max-w-lg w-full">
        <h3 class="text-lg font-semibold mb-4">Confirm Selections</h3>
        <p class="mb-3">You are about to replace the team's selections with the following players:</p>
        <ul class="mb-4 list-disc list-inside max-h-40 overflow-y-auto">
          <li v-for="id in selectedIds" :key="id">{{ players.find(p => p.id === id)?.name }}</li>
        </ul>
        <div class="mb-4 text-sm">Captain: <strong>{{ players.find(p => p.id === captainId)?.name }}</strong> — Vice: <strong>{{ players.find(p => p.id === viceCaptainId)?.name }}</strong></div>
        <div class="flex justify-end gap-2">
          <button @click="showConfirm = false" class="px-4 py-2 bg-gray-200 rounded">Cancel</button>
          <button @click.prevent="confirmSubmit" class="px-4 py-2 btn-primary">Confirm</button>
        </div>
      </div>
    </div>
  </AdminLayout>
</template>
