<script setup>
import { Head, Link, router } from '@inertiajs/vue3'
import AdminLayout from '@/Layouts/AdminLayout.vue'
import { ref } from 'vue'
import { Inertia } from '@inertiajs/inertia'

const props = defineProps({ teams: Object, filters: Object })

const q = ref(props.filters?.q || '')
const perPage = ref(props.filters?.per_page || 25)

let debounceTimer = null
function debouncedSearch() {
  clearTimeout(debounceTimer)
  debounceTimer = setTimeout(searchNow, 450)
}

function searchNow() {
  Inertia.get(route('admin.fantasy-teams.index'), { q: q.value, per_page: perPage.value }, { preserveState: true, replace: true })
}

function deleteTeam(teamId) {
  if (window.confirm('Delete this team? This action cannot be undone.')) {
    router.delete(`/admin/fantasy-teams/${teamId}`)
  }
}
</script>

<template>
  <Head title="Fantasy Teams" />

  <AdminLayout>
    <div class="space-y-6">
      <!-- Header -->
      <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 class="text-3xl font-bold text-gray-900">⚽ Fantasy Teams</h1>
          <p class="text-gray-600 mt-1">Manage fantasy teams for tournaments</p>
        </div>
        <Link href="/admin/fantasy-teams/create" class="px-4 py-2 btn-success">
          + Create Team
        </Link>
      </div>

      <form @submit.prevent class="mb-4 space-y-3 sm:space-y-0">
        <div class="flex flex-col sm:flex-row gap-2 items-start sm:items-center">
          <input v-model="q" placeholder="Search teams, users or tournaments" class="border rounded px-3 py-2 flex-1" @input="debouncedSearch" />
          <select v-model="perPage" class="border rounded px-2 py-2 w-full sm:w-auto">
            <option value="10">10</option>
            <option value="25">25</option>
            <option value="50">50</option>
            <option value="100">100</option>
          </select>
          <div class="flex gap-2 w-full sm:w-auto">
            <button type="button" @click="searchNow" class="flex-1 sm:flex-none px-3 py-2 btn-primary">Search</button>
            <Link :href="route('admin.fantasy-teams.index')" class="flex-1 sm:flex-none px-3 py-2 border rounded text-center">Clear</Link>
          </div>
        </div>
      </form>

      <div v-if="!teams.data.length" class="bg-white rounded-xl shadow-lg p-12 text-center">
        <p class="text-gray-500 text-lg mb-4">⚽ No fantasy teams found</p>
        <Link href="/admin/fantasy-teams/create" class="px-4 py-2 btn-success">
          + Create the first team
        </Link>
      </div>

      <div v-else class="sm:hidden space-y-3">
        <div v-for="(t, idx) in teams.data" :key="t.id" class="bg-white p-4 rounded-lg shadow border-l-4 border-blue-500">
          <div class="flex justify-between items-start mb-3">
            <h3 class="font-semibold text-gray-900">{{ t.name || '—' }}</h3>
            <span v-if="t.status === 'approved'" class="badge bg-green-100 text-green-800">✓ Approved</span>
            <span v-else-if="t.status === 'rejected'" class="badge bg-red-100 text-red-800">✗ Rejected</span>
            <span v-else class="badge bg-yellow-100 text-yellow-800">⏳ Pending</span>
          </div>
          <div class="space-y-2 text-sm text-gray-600 mb-3">
            <p><strong>User:</strong> {{ t.user ? t.user.name : '—' }}</p>
            <p><strong>Tournament:</strong> {{ t.tournament ? t.tournament.name : '—' }}</p>
            <p><strong>Players:</strong> {{ t.player_ids ? t.player_ids.length : 0 }}/11</p>
          </div>
          <div class="flex gap-2 pt-3 border-t">
            <Link :href="`/admin/fantasy-teams/${t.id}/edit`" class="btn-primary btn-sm">✏️ Edit</Link>
            <button type="button" @click="deleteTeam(t.id)" class="btn-danger btn-sm">🗑️ Delete</button>
          </div>
        </div>
      </div>

      <!-- Desktop Table View -->
      <div v-if="teams.data.length" class="hidden sm:block bg-white rounded-xl shadow-lg overflow-hidden">
        <table class="w-full">
          <thead class="bg-gray-50 border-b border-gray-200">
            <tr>
              <th class="px-6 py-3 text-left text-xs font-semibold text-gray-700">#</th>
              <th class="px-6 py-3 text-left text-xs font-semibold text-gray-700">Team Name</th>
              <th class="px-6 py-3 text-left text-xs font-semibold text-gray-700">User</th>
              <th class="px-6 py-3 text-left text-xs font-semibold text-gray-700">Tournament</th>
              <th class="px-6 py-3 text-left text-xs font-semibold text-gray-700">Players</th>
              <th class="px-6 py-3 text-left text-xs font-semibold text-gray-700">Status</th>
              <th class="px-6 py-3 text-center text-xs font-semibold text-gray-700">Actions</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-200">
            <tr v-for="(t, idx) in teams.data" :key="t.id" class="hover:bg-gray-50 transition-colors">
              <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">{{ idx + 1 }}</td>
              <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">{{ t.name || '—' }}</td>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-700">{{ t.user ? t.user.name : '—' }}</td>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-700">{{ t.tournament ? t.tournament.name : '—' }}</td>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-700">
                <span class="badge bg-blue-100 text-blue-800">
                  {{ t.player_ids ? t.player_ids.length : 0 }}/11
                </span>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm">
                <span v-if="t.status === 'approved'" class="badge bg-green-100 text-green-800">
                  ✓ Approved
                </span>
                <span v-else-if="t.status === 'rejected'" class="badge bg-red-100 text-red-800">
                  ✗ Rejected
                </span>
                <span v-else-if="t.status === 'canceled'" class="badge bg-gray-100 text-gray-800">
                  ✗ Canceled
                </span>
                <span v-else class="badge bg-yellow-100 text-yellow-800">
                  ⏳ Pending
                </span>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-center">
                <div class="flex gap-1 justify-center">
                  <Link :href="`/admin/fantasy-teams/${t.id}/edit`" class="btn-primary btn-sm">✏️ Edit</Link>
                  <button type="button" @click="deleteTeam(t.id)" class="btn-danger btn-sm">🗑️ Delete</button>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <div class="mt-4">
      <Link v-if="teams.prev_page_url" :href="teams.prev_page_url" class="mr-2">Prev</Link>
      <Link v-if="teams.next_page_url" :href="teams.next_page_url">Next</Link>
    </div>

  </AdminLayout>
</template>
