<script setup>
import { Head, useForm } from '@inertiajs/vue3'
import AdminLayout from '@/Layouts/AdminLayout.vue'
import { ref, computed } from 'vue'

defineOptions({
  layout: AdminLayout,
})

const { tournaments, winners: initialWinners } = defineProps({
  tournaments: Array,
  winners: Array,
})

const selectedTournament = ref(null)
const limit = ref(10)
const topUsers = ref([])
const loading = ref(false)
const saving = ref(false)
const successMessage = ref('')
const errorMessage = ref('')
const winners = ref(initialWinners || [])

// Form for getting top users
const getTopForm = useForm({
  tournament_id: '',
  limit: 10,
})

async function fetchTopUsers() {
  if (!getTopForm.tournament_id) {
    errorMessage.value = 'Please select a tournament'
    return
  }

  loading.value = true
  errorMessage.value = ''
  successMessage.value = ''

  try {
    const response = await fetch(route('admin.winners.getTopUsers'), {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
      },
      body: JSON.stringify({
        tournament_id: getTopForm.tournament_id,
        limit: getTopForm.limit,
      }),
    })

    const data = await response.json()

    if (data.success) {
      topUsers.value = data.data
      successMessage.value = `Found ${data.data.length} top users`
    } else {
      errorMessage.value = data.message || 'Failed to fetch top users'
    }
  } catch (error) {
    errorMessage.value = 'Error fetching top users: ' + error.message
  } finally {
    loading.value = false
  }
}

async function saveWinners() {
  if (!getTopForm.tournament_id) {
    errorMessage.value = 'Please select a tournament'
    return
  }

  if (topUsers.value.length === 0) {
    errorMessage.value = 'No users to save. Please fetch top users first.'
    return
  }

  saving.value = true
  errorMessage.value = ''
  successMessage.value = ''

  try {
    const response = await fetch(route('admin.winners.save'), {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
      },
      body: JSON.stringify({
        tournament_id: getTopForm.tournament_id,
        winners: topUsers.value,
      }),
    })

    const data = await response.json()

    if (data.success) {
      successMessage.value = 'Winners saved successfully!'
      // Refresh winners list with a winner record for this tournament
      const record = {
        id: Date.now(),
        tournament_id: parseInt(getTopForm.tournament_id),
        tournament_name: getTournamentName(getTopForm.tournament_id),
        fantasy_teams_ids: topUsers.value.map(u => u.fantasy_team_id),
        fantasy_teams_names: topUsers.value.map(u => u.fantasy_team_name),
        user_ids: topUsers.value.map(u => u.user_id),
        user_names: topUsers.value.map(u => u.user_name),
        total_points: topUsers.value.map(u => u.total_points),
        status: 'active',
      }
      // Remove existing winner for this tournament (if any) and add new
      winners.value = winners.value.filter(w => w.tournament_id !== record.tournament_id)
      winners.value.push(record)
      topUsers.value = []
    } else {
      errorMessage.value = data.message || 'Failed to save winners'
    }
  } catch (error) {
    errorMessage.value = 'Error saving winners: ' + error.message
  } finally {
    saving.value = false
  }
}

const filteredWinners = computed(() => {
  if (!getTopForm.tournament_id) return []
  return winners.value.filter(w => w.tournament_id === parseInt(getTopForm.tournament_id))
})

const getTournamentName = (id) => {
  return tournaments.find(t => t.id === id)?.name || 'Unknown'
}

const getWinnerRowsFor = (winner) => {
  if (!winner) return []
  // If winner stored as arrays (DB record with multiple winners)
  if (winner.fantasy_teams_ids && Array.isArray(winner.fantasy_teams_ids) && winner.fantasy_teams_ids.length > 0) {
    return winner.fantasy_teams_ids.map((id, idx) => ({
      rank: idx + 1,
      fantasy_team_name: winner.fantasy_teams_names?.[idx] ?? '',
      user_name: winner.user_names?.[idx] ?? '',
      total_points: winner.total_points?.[idx] ?? 0,
    }))
  }
  // Fallback for per-user objects (e.g., just fetched topUsers or older shape)
  if (winner.fantasy_team_id || winner.fantasy_team_name) {
    return [{
      rank: winner.rank || 1,
      fantasy_team_name: winner.fantasy_team_name || '',
      user_name: winner.user_name || '',
      total_points: winner.total_points || 0,
    }]
  }
  return []
}
</script>

<template>
  <Head title="Winners Management" />

  <div class="space-y-8">
      <!-- Header -->
      <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 class="text-3xl font-bold text-gray-900">⚙️ Winners Management</h1>
          <p class="text-gray-600 mt-1">Fetch and save tournament winners</p>
        </div>
        <div class="flex gap-2">
          <a href="/admin/winners" class="px-4 py-2 bg-gray-600 text-white rounded-lg hover:bg-gray-700 transition-colors font-semibold">
            ← Back to All Winners
          </a>
        </div>
      </div>

      <!-- Messages -->
      <div v-if="successMessage" class="bg-green-50 border-l-4 border-green-500 p-4 rounded">
        <p class="text-green-800">✅ {{ successMessage }}</p>
      </div>
      <div v-if="errorMessage" class="bg-red-50 border-l-4 border-red-500 p-4 rounded">
        <p class="text-red-800">❌ {{ errorMessage }}</p>
      </div>

      <!-- Input Section -->
      <div class="bg-white rounded-xl shadow-lg p-8">
        <div class="mb-6">
          <h2 class="text-2xl font-bold text-gray-900 mb-2">📊 Fetch Top Users</h2>
          <p class="text-gray-600">Select a tournament and number of winners to display</p>
        </div>

        <div class="space-y-6">
          <!-- Tournament Selection -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">Tournament</label>
            <select
              v-model="getTopForm.tournament_id"
              class="w-full px-4 py-2 border-2 border-gray-300 rounded-lg focus:outline-none focus:border-blue-500"
            >
              <option value="">-- Select Tournament --</option>
              <option v-for="tournament in tournaments" :key="tournament.id" :value="tournament.id">
                {{ tournament.name }}
              </option>
            </select>
          </div>

          <!-- Limit Input -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">Number of Winners</label>
            <input
              v-model.number="getTopForm.limit"
              type="number"
              min="1"
              max="100"
              class="w-full px-4 py-2 border-2 border-gray-300 rounded-lg focus:outline-none focus:border-blue-500"
              placeholder="10"
            />
            <p class="text-sm text-gray-500 mt-1">Enter a number between 1 and 100</p>
          </div>

          <!-- Fetch Button -->
          <div class="flex gap-3">
            <button
              @click="fetchTopUsers"
              :disabled="loading || !getTopForm.tournament_id"
              class="px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-all disabled:opacity-50 disabled:cursor-not-allowed font-medium"
            >
              {{ loading ? '🔄 Fetching...' : '🔍 Fetch Top Users' }}
            </button>
          </div>
        </div>
      </div>

      <!-- Results Section -->
      <div v-if="topUsers.length > 0" class="bg-white rounded-xl shadow-lg p-8">
        <div class="mb-6">
          <h2 class="text-2xl font-bold text-gray-900 mb-2">👥 Top {{ topUsers.length }} Users</h2>
          <p class="text-gray-600">Review the results below and save them to the winners table</p>
        </div>

        <div class="overflow-x-auto">
          <table class="w-full text-left">
            <thead class="bg-gray-50 border-b-2 border-gray-200">
              <tr>
                <th class="px-4 py-3 font-semibold text-gray-700">Rank</th>
                <th class="px-4 py-3 font-semibold text-gray-700">Fantasy Team</th>
                <th class="px-4 py-3 font-semibold text-gray-700">User Name</th>
                <th class="px-4 py-3 font-semibold text-gray-700">Email</th>
                <th class="px-4 py-3 font-semibold text-gray-700">Points</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="(user, index) in topUsers" :key="index" class="border-b border-gray-200 hover:bg-gray-50">
                <td class="px-4 py-3 font-bold text-blue-600">{{ user.rank }}</td>
                <td class="px-4 py-3">{{ user.fantasy_team_name }}</td>
                <td class="px-4 py-3">{{ user.user_name }}</td>
                <td class="px-4 py-3 text-sm text-gray-600">{{ user.user_email }}</td>
                <td class="px-4 py-3 font-semibold">{{ user.total_points }}</td>
              </tr>
            </tbody>
          </table>
        </div>

        <!-- Save Button -->
        <div class="mt-6 flex gap-3">
          <button
            @click="saveWinners"
            :disabled="saving || topUsers.length === 0"
            class="px-6 py-3 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed font-medium"
          >
            {{ saving ? '💾 Saving...' : '💾 Save as Winners' }}
          </button>
        </div>
      </div>

      <!-- Existing Winners Section -->
      <div v-if="filteredWinners.length > 0" class="bg-white rounded-xl shadow-lg p-8">
        <div class="mb-6">
          <h2 class="text-2xl font-bold text-gray-900 mb-2">🏅 Current Winners</h2>
          <p class="text-gray-600">Winners saved for {{ getTournamentName(getTopForm.tournament_id) }}</p>
        </div>

        <div class="overflow-x-auto">
          <table class="w-full text-left">
            <thead class="bg-gray-50 border-b-2 border-gray-200">
              <tr>
                <th class="px-4 py-3 font-semibold text-gray-700">Rank</th>
                <th class="px-4 py-3 font-semibold text-gray-700">Fantasy Team</th>
                <th class="px-4 py-3 font-semibold text-gray-700">User Name</th>
                <th class="px-4 py-3 font-semibold text-gray-700">Email</th>
                <th class="px-4 py-3 font-semibold text-gray-700">Points</th>
              </tr>
            </thead>
            <tbody>
              <template v-for="winnerRecord in filteredWinners" :key="winnerRecord.id">
                <tr v-for="(row, idx) in getWinnerRowsFor(winnerRecord)" :key="winnerRecord.id + '-' + idx" class="border-b border-gray-200 hover:bg-gray-50">
                  <td class="px-4 py-3 font-bold text-blue-600">{{ row.rank }}</td>
                  <td class="px-4 py-3">{{ row.fantasy_team_name }}</td>
                  <td class="px-4 py-3">{{ row.user_name }}</td>
                  <td class="px-4 py-3 text-sm text-gray-600">{{ row.total_points }}</td>
                </tr>
              </template>
            </tbody>
          </table>
        </div>
      </div>


    </div>
</template>
