<script setup>
import { Head, Link } from '@inertiajs/vue3'
import AdminLayout from '@/Layouts/AdminLayout.vue'
import { ref } from 'vue'
import { Inertia } from '@inertiajs/inertia'

defineOptions({
  layout: AdminLayout,
})

const props = defineProps({ points: Object, filters: Object })

const q = ref(props.filters?.q || '')
const perPage = ref(props.filters?.per_page || 15)

let debounceTimer = null
function debouncedSearch() {
  clearTimeout(debounceTimer)
  debounceTimer = setTimeout(searchNow, 450)
}

function searchNow() {
  Inertia.get(route('admin.points.index'), { q: q.value, per_page: perPage.value }, { preserveState: true, replace: true })
}

const confirmDeleteId = ref(null)
const deleting = ref(false)

function confirmDelete(id) {
  confirmDeleteId.value = id
}

function cancelDelete() {
  confirmDeleteId.value = null
}

function deletePoint(id) {
  deleting.value = true
  $inertia.delete(route('admin.points.destroy', id)).finally(() => {
    deleting.value = false
    confirmDeleteId.value = null
  })
}

// Helper: format match teams robustly whether relations or fallback fields are present
const formatMatchTeams = (m) => {
  if (!m) return '—'
  const a = m.teamA?.name ?? (typeof m.team_a === 'string' ? m.team_a : (m.team_a && m.team_a.name))
  const b = m.teamB?.name ?? (typeof m.team_b === 'string' ? m.team_b : (m.team_b && m.team_b.name))
  return `${a || 'Team A'} vs ${b || 'Team B'}`
}
</script>

<template>
  <Head title="Match Points" />

  <div class="space-y-6">
      <!-- Header -->
      <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 class="text-3xl font-bold text-gray-900">📊 Match Points</h1>
          <p class="text-gray-600 mt-1">Manage player match points</p>
        </div>
        <Link href="/admin/points/create" class="px-4 py-2 btn-success">
          + Create Point
        </Link>
      </div>

      <!-- Mobile Card View -->
      <div class="sm:hidden space-y-3">
        <div v-for="(p, idx) in points.data" :key="p.id" class="bg-white p-4 rounded-lg shadow border-l-4 border-blue-500">
          <p class="font-bold text-gray-900">{{ p.player.name }}</p>
          <p class="text-sm text-gray-600">Team: {{ p.team ? p.team.name : '—' }}</p>
          <p class="text-sm text-gray-600">Tournament: {{ p.tournament.name }}</p>
          <div class="mt-2 flex items-center justify-between">
            <span class="badge bg-blue-100 text-blue-800">{{ p.points }} pts</span>
            <div class="flex gap-2">
              <Link :href="`/admin/points/${p.id}/edit`" class="btn-primary btn-sm">✏️ Edit</Link>
              <button type="button" @click.prevent="confirmDelete(p.id)" class="btn-danger btn-sm">🗑️ Delete</button>
            </div>
          </div>
        </div>
        <div v-if="!points || !points.data || points.data.length === 0" class="text-center py-8 text-gray-500">
          <div class="flex flex-col items-center gap-3">
            <span class="text-4xl">📊</span>
            <p class="text-lg font-semibold">No points found</p>
            <p class="text-sm">Create one to get started</p>
          </div>
        </div>
      </div>

      <!-- Search and Filter -->
      <form @submit.prevent class="mb-4 space-y-3 sm:space-y-0">
        <div class="flex flex-col sm:flex-row gap-2 items-start sm:items-center">
          <input v-model="q" placeholder="Search player, match, tournament" class="border rounded px-3 py-2 flex-1" @input="debouncedSearch" />
          <select v-model="perPage" class="border rounded px-2 py-2 w-full sm:w-auto">
            <option value="10">10</option>
            <option value="15">15</option>
            <option value="25">25</option>
            <option value="50">50</option>
          </select>
          <div class="flex gap-2 w-full sm:w-auto">
            <button type="button" @click="searchNow" class="flex-1 sm:flex-none px-3 py-2 btn-primary">Search</button>
            <Link :href="route('admin.points.index')" class="flex-1 sm:flex-none px-3 py-2 border rounded text-center">Clear</Link>
          </div>
        </div>
      </form>

      <!-- Points Table -->
      <div class="bg-white shadow rounded-lg overflow-hidden">
        <div class="overflow-x-auto w-full">
          <table class="w-full">
            <thead class="bg-gray-50 border-b border-gray-200">
              <tr>
                <th class="px-6 py-3 text-left text-xs font-semibold text-gray-700">#</th>
                <th class="px-6 py-3 text-left text-xs font-semibold text-gray-700">Player</th>
                <th class="px-6 py-3 text-left text-xs font-semibold text-gray-700">Game Match</th>
                <th class="px-6 py-3 text-left text-xs font-semibold text-gray-700">Tournament</th>
                <th class="px-6 py-3 text-left text-xs font-semibold text-gray-700">Points</th>
                <th class="px-6 py-3 text-left text-xs font-semibold text-gray-700">Actions</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-200">
              <tr v-for="(p, idx) in points.data" :key="p.id" class="hover:bg-gray-50">
                <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">{{ idx + 1 + (points.meta && points.meta.current_page && points.meta.per_page ? ((points.meta.current_page - 1) * points.meta.per_page) : 0) }}</td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">{{ p.player.name }}</td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-700">{{ formatMatchTeams(p.game_match) }}</td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-700">{{ p.tournament ? p.tournament.name : '—' }}</td>
                <td class="px-6 py-4 whitespace-nowrap text-sm font-bold text-gray-900">{{ p.points }}</td>
                <td class="px-6 py-4 whitespace-nowrap text-sm font-medium">
                  <div class="flex gap-2">
                    <Link :href="`/admin/points/${p.id}/edit`" class="btn-primary btn-sm">✏️ Edit</Link>
                    <button type="button" @click.prevent="confirmDelete(p.id)" :disabled="deleting" class="btn-danger btn-sm">🗑️ Delete</button>
                  </div>
                </td>
              </tr>
              <tr v-if="!points || !points.data || points.data.length === 0">
                <td colspan="6" class="px-6 py-12 text-center">
                  <div class="flex flex-col items-center gap-3 text-gray-500">
                    <span class="text-4xl">📊</span>
                    <p class="text-lg font-semibold">No points found</p>
                    <p class="text-sm">Create one to get started</p>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
        <!-- Pagination -->
        <div class="flex flex-col sm:flex-row items-start sm:items-center justify-between px-6 py-4 border-t border-gray-200 gap-4">
          <p class="text-sm text-gray-600">Showing {{ points.from || 0 }} to {{ points.to || 0 }} of {{ points.total }} records</p>
          <div class="flex gap-2 w-full sm:w-auto items-center">
            <Link
              v-if="points.prev_page_url"
              :href="points.prev_page_url"
              class="flex-1 sm:flex-none px-4 py-2 bg-gray-200 text-gray-800 rounded-lg hover:bg-gray-300 transition-colors font-semibold text-center"
            >
              ⬅ Previous
            </Link>
            <Link
              v-if="points.next_page_url"
              :href="points.next_page_url"
              class="flex-1 sm:flex-none px-4 py-2 btn-primary text-center"
            >
              Next ➡
            </Link>
            <span v-if="!points.prev_page_url && !points.next_page_url" class="text-sm text-gray-500">Page {{ points.current_page || 1 }} of {{ points.last_page || 1 }}</span>
          </div>
        </div>
      </div>
    </div>

  <!-- Confirm Delete Modal -->
  <div v-if="confirmDeleteId" class="fixed inset-0 bg-black bg-opacity-30 flex items-center justify-center">
    <div class="bg-white rounded p-6 w-full max-w-md">
      <h3 class="text-lg font-semibold mb-4">Confirm delete</h3>
      <p class="mb-4">Are you sure you want to delete this point record? This action cannot be undone.</p>
      <div class="flex justify-end gap-2">
        <button @click="cancelDelete" class="px-4 py-2 border rounded">Cancel</button>
        <button @click="deletePoint(confirmDeleteId)" :disabled="deleting" class="btn-danger">Delete</button>
      </div>
    </div>
  </div>
</template>
