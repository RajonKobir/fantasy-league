<script setup>
import { Head, Link, router } from '@inertiajs/vue3'
import { ref } from 'vue'
import { Inertia } from '@inertiajs/inertia'
import AdminLayout from '@/Layouts/AdminLayout.vue'
import { useDate } from '@/composables/useDate'

const { formatDate } = useDate()

const props = defineProps({
  gameMatches: Object, // paginated { data, links, meta }
  filters: Object,
})

const q = ref(props.filters?.q || '')
const perPage = ref(props.filters?.per_page || 15)

let debounceTimer = null
function debouncedSearch() {
  clearTimeout(debounceTimer)
  debounceTimer = setTimeout(searchNow, 450)
}

function searchNow() {
  Inertia.get(route('admin.game-matches.index'), { q: q.value, per_page: perPage.value }, { preserveState: true, replace: true })
}

function deleteMatch(matchId) {
  if (window.confirm('Delete this match? This action cannot be undone.')) {
    router.delete(`/admin/game-matches/${matchId}`)
  }
}
</script>

<template>
  <Head title="Game Matches" />

  <AdminLayout>
    <div class="space-y-6">
      <!-- Header -->
      <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 class="text-3xl font-bold text-gray-900">Game Matches</h1>
          <p class="text-gray-600 mt-1">Manage Game Matches for tournaments</p>
        </div>

        <div class="flex items-center gap-3">
          <Link :href="route('admin.game-matches.create')" class="px-4 py-2 btn-success">
            ➕ Create Match
          </Link>
        </div>
      </div>

      <!-- Search and Filter -->
      <form @submit.prevent class="mb-4 space-y-3 sm:space-y-0">
        <div class="flex flex-col sm:flex-row gap-2 items-start sm:items-center">
          <input v-model="q" placeholder="Search by teams or title" class="border rounded px-3 py-2 flex-1" @input="debouncedSearch" />
          <select v-model="perPage" class="border rounded px-2 py-2 w-full sm:w-auto">
            <option value="10">10</option>
            <option value="15">15</option>
            <option value="25">25</option>
            <option value="50">50</option>
          </select>
          <div class="flex gap-2 w-full sm:w-auto">
            <button type="button" @click="searchNow" class="flex-1 sm:flex-none px-3 py-2 btn-primary">Search</button>
            <Link :href="route('admin.game-matches.index')" class="flex-1 sm:flex-none px-3 py-2 border rounded text-center">Clear</Link>
          </div>
        </div>
      </form>

      <!-- Mobile Card View -->
      <div class="sm:hidden space-y-3">
        <div v-for="match in gameMatches.data" :key="match.id" class="bg-white p-4 rounded-lg shadow border-l-4 border-blue-500">
          <p class="font-bold text-gray-900">{{ match.tournament?.name || 'N/A' }}</p>
          <p class="text-sm text-gray-700">{{ match.team_a || 'N/A' }} vs {{ match.team_b || 'N/A' }}</p>
          <p class="text-sm text-gray-600">{{ formatDate(match.scheduled_at) }}</p>
          <div class="mt-2">
            <span class="badge" :class="match.status === 'scheduled' ? 'bg-blue-100 text-blue-800' : match.status === 'live' ? 'bg-red-100 text-red-800' : match.status === 'completed' ? 'bg-green-100 text-green-800' : 'bg-gray-100 text-gray-800'">
              {{ match.status?.charAt(0).toUpperCase() + match.status?.slice(1) || 'Unknown' }}
            </span>
          </div>
          <div class="flex gap-2 pt-3 border-t mt-3">
            <Link :href="`/admin/game-matches/${match.id}/edit`" class="btn-primary btn-sm">✏️ Edit</Link>
            <button @click="deleteMatch(match.id)" class="btn-danger btn-sm">🗑️ Delete</button>
          </div>
        </div>
      </div>

      <!-- Matches Table -->
      <div class="bg-white rounded-xl shadow-lg overflow-hidden">
        <div class="overflow-x-auto">
          <table class="w-full">
            <thead>
              <tr class="bg-gray-50 border-b border-gray-200">
                <th class="px-6 py-3 text-left text-xs font-semibold text-gray-700">Tournament</th>
                <th class="px-6 py-3 text-left text-xs font-semibold text-gray-700">Team 1</th>
                <th class="px-6 py-3 text-left text-xs font-semibold text-gray-700">Team 2</th>
                <th class="px-6 py-3 text-left text-xs font-semibold text-gray-700">Scheduled At</th>
                <th class="px-6 py-3 text-left text-xs font-semibold text-gray-700">Status</th>
                <th class="px-6 py-3 text-center text-xs font-semibold text-gray-700">Actions</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-200">
              <tr v-for="match in gameMatches.data" :key="match.id" class="hover:bg-gray-50 transition-colors">
                <td class="px-6 py-4 text-sm text-gray-900">{{ match.tournament?.name || 'N/A' }}</td>
                <td class="px-6 py-4 text-sm text-gray-900">{{ match.team_a || 'N/A' }}</td>
                <td class="px-6 py-4 text-sm text-gray-900">{{ match.team_b || 'N/A' }}</td>
                <td class="px-6 py-4 text-sm text-gray-900">{{ formatDate(match.scheduled_at) }}</td>
                <td class="px-6 py-4 text-sm">
                  <span :class="[
                    'inline-block px-2 py-1 rounded text-xs font-semibold',
                    match.status === 'scheduled' ? 'bg-blue-100 text-blue-800' :
                    match.status === 'live' ? 'bg-red-100 text-red-800' :
                    match.status === 'completed' ? 'bg-green-100 text-green-800' :
                    'bg-gray-100 text-gray-800'
                  ]">
                    {{ match.status?.charAt(0).toUpperCase() + match.status?.slice(1) || 'Unknown' }}
                  </span>
                </td>
                <td class="px-6 py-4 text-sm text-center">
                  <div class="flex justify-center gap-2">
                    <Link :href="`/admin/game-matches/${match.id}/edit`" class="btn-primary btn-sm">
                      ✏️ Edit
                    </Link>
                    <button
                      @click="deleteMatch(match.id)"
                      class="btn-danger btn-sm"
                    >
                      🗑️ Delete
                    </button>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <!-- Pagination -->
    </div>
  </AdminLayout>
</template>
