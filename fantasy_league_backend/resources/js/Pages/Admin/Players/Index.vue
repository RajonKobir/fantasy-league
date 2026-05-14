<script setup>
import { Head, Link, router } from '@inertiajs/vue3'
import AdminLayout from '@/Layouts/AdminLayout.vue'
import { ref } from 'vue'
import { Inertia } from '@inertiajs/inertia'

const props = defineProps({
  players: Object, // paginated { data, links, meta }
  filters: Object,
})

const q = ref(props.filters?.q || '')
const perPage = ref(props.filters?.per_page || 25)

let debounceTimer = null
function debouncedSearch() {
  clearTimeout(debounceTimer)
  debounceTimer = setTimeout(searchNow, 450)
}

function searchNow() {
  Inertia.get(route('admin.players.index'), { q: q.value, per_page: perPage.value }, { preserveState: true, replace: true })
}

function deletePlayer(playerId) {
  if (window.confirm('Delete this player? This action cannot be undone.')) {
    router.delete(`/admin/players/${playerId}`)
  }
}
</script>

<template>
  <Head title="Players" />

  <AdminLayout>
    <div class="space-y-6">
      <!-- Header -->
      <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 class="text-3xl font-bold text-gray-900">🏏 All Players</h1>
          <p class="text-gray-600 mt-1">Manage all players in the system</p>
        </div>
        <div class="flex gap-2">
          <Link href="/admin/players/create" class="px-4 py-2 btn-success">
            + Create Player
          </Link>
          <Link href="/admin/dashboard" class="px-4 py-2 bg-gray-200 text-gray-800 rounded-lg hover:bg-gray-300 transition-colors font-semibold">
            ⬅ Back
          </Link>
        </div>
      </div>

      <form @submit.prevent class="mb-4 space-y-3 sm:space-y-0">
        <div class="flex flex-col sm:flex-row gap-2 items-start sm:items-center">
          <input v-model="q" placeholder="Search by name or team" class="border rounded px-3 py-2 flex-1" @input="debouncedSearch" />
          <select v-model="perPage" class="border rounded px-2 py-2 w-full sm:w-auto">
            <option value="10">10</option>
            <option value="15">15</option>
            <option value="25">25</option>
            <option value="50">50</option>
            <option value="100">100</option>
          </select>
          <div class="flex gap-2 w-full sm:w-auto">
            <button type="button" @click="searchNow" class="flex-1 sm:flex-none px-3 py-2 btn-primary">Search</button>
            <Link :href="route('admin.players.index')" class="flex-1 sm:flex-none px-3 py-2 border rounded text-center">Clear</Link>
          </div>
        </div>
      </form>

      <!-- Players Table -->
      <template v-if="!players || !players.data || players.data.length === 0">
        <div class="bg-white shadow rounded-lg p-8 text-center">
          <p class="text-gray-500 text-lg">No players found</p>
          <p class="text-gray-400 text-sm mt-2">Total in response: {{ players?.total || 0 }}</p>
          <Link href="/admin/players/create" class="mt-4 inline-block px-4 py-2 btn-primary">
            Create the first player
          </Link>
        </div>
      </template>

      <template v-else>
        <!-- Mobile Card View -->
        <div class="sm:hidden space-y-3">
          <div v-for="player in players.data" :key="player.id" class="bg-white p-4 rounded-lg shadow border-l-4 border-blue-500">
            <div class="flex gap-3 items-start">
              <div class="flex-1">
                <p class="font-bold text-gray-900">#{{ player.id }}: {{ player.name }}</p>
                <p class="text-sm text-gray-600 mt-1">Team: {{ player.team }}</p>
                <div class="flex gap-2 mt-2">
                  <span class="badge bg-blue-100 text-blue-800">
                    {{ player.role }}
                  </span>
                  <span v-if="player.is_playing" class="badge bg-green-100 text-green-800">
                    Playing
                  </span>
                  <span v-else class="badge bg-gray-100 text-gray-800">
                    Inactive
                  </span>
                </div>
              </div>
            </div>
            <div class="flex gap-2 pt-3 border-t mt-3">
              <Link :href="`/admin/players/${player.id}/edit`" class="btn-primary btn-sm">✏️ Edit</Link>
              <button type="button" @click="deletePlayer(player.id)" class="btn-danger btn-sm">🗑️ Delete</button>
            </div>
          </div>
        </div>

        <!-- Desktop Table View -->
        <div class="hidden sm:block bg-white shadow rounded-lg">
        <div class="overflow-x-auto w-full">
          <table class="w-full">
            <thead class="bg-gray-50 border-b border-gray-200">
              <tr>
                <th class="px-6 py-3 text-left text-xs font-semibold text-gray-700">#</th>
                <th class="px-6 py-3 text-left text-xs font-semibold text-gray-700">Name</th>
                <th class="px-6 py-3 text-left text-xs font-semibold text-gray-700">Role</th>
                <th class="px-6 py-3 text-left text-xs font-semibold text-gray-700">Nationality</th>
                <th class="px-6 py-3 text-left text-xs font-semibold text-gray-700">Playing</th>
                <th class="px-6 py-3 text-left text-xs font-semibold text-gray-700">Actions</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-200">
              <tr v-for="player in players.data" :key="player.id" class="hover:bg-gray-50">
                <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">{{ player.id }}</td>
                <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">{{ player.name }}</td>
                <td class="px-6 py-4 whitespace-nowrap text-sm">
                  <span class="badge bg-blue-100 text-blue-800">
                    {{ player.role }}
                  </span>
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-700">{{ player.nationality || '-' }}</td>
                <td class="px-6 py-4 whitespace-nowrap text-sm">
                  <span v-if="player.is_playing" class="badge bg-green-100 text-green-800">
                    Yes
                  </span>
                  <span v-else class="badge bg-gray-100 text-gray-800">
                    No
                  </span>
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm font-medium">
                  <div class="flex gap-2">
                    <Link :href="`/admin/players/${player.id}/edit`" class="btn-primary btn-sm">✏️ Edit</Link>
                    <button type="button" @click="deletePlayer(player.id)" class="btn-danger btn-sm">🗑️ Delete</button>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <!-- Pagination -->
        <div class="px-6 py-4 border-t border-gray-200">
          <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
            <p class="text-sm text-gray-600">
              Showing <span class="font-semibold">{{ players.from || 0 }}</span> to
              <span class="font-semibold">{{ players.to || 0 }}</span> of
              <span class="font-semibold">{{ players.total || 0 }}</span> players
            </p>
            <div v-if="players.links.length > 3" class="flex gap-2 flex-wrap">
              <Link
                v-for="link in players.links"
                :key="link.label"
                :href="link.url || '#'"
                :onclick="!link.url ? 'return false' : null"
                class="px-3 py-1 text-sm rounded border transition-colors"
                :class="link.active ? 'bg-blue-600 text-white border-blue-600' : 'border-gray-300 text-gray-700 hover:bg-gray-50'"
                v-html="link.label"
              />
            </div>
          </div>
        </div>
      </div>
      </template>
    </div>
  </AdminLayout>
</template>
