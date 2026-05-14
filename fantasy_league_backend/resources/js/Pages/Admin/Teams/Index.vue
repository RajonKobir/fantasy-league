<script setup>
import { Head, Link, router } from '@inertiajs/vue3'
import AdminLayout from '@/Layouts/AdminLayout.vue'
import { ref } from 'vue'
import { Inertia } from '@inertiajs/inertia'

const props = defineProps({ teams: Object, filters: Object, users: Array })

const q = ref(props.filters?.q || '')
const perPage = ref(props.filters?.per_page || 15)

let debounceTimer = null
function debouncedSearch() {
  clearTimeout(debounceTimer)
  debounceTimer = setTimeout(searchNow, 450)
}

function searchNow() {
  Inertia.get(route('admin.teams.index'), { q: q.value, per_page: perPage.value }, { preserveState: true, replace: true })
}

// Bulk actions removed: single-team actions remain (Edit/Delete/Selections)

function sortBy(column) {
  const current = props.filters?.sort_by
  const currentDir = props.filters?.sort_dir || 'desc'
  let dir = 'desc'
  if (current === column) dir = currentDir === 'desc' ? 'asc' : 'desc'
  Inertia.get(route('admin.teams.index'), { ...props.filters, sort_by: column, sort_dir: dir }, { preserveState: true, replace: true })
}

function deleteTeam(teamId, teamName) {
  if (window.confirm(`Delete team "${teamName}"? This action cannot be undone.`)) {
    router.delete(route('admin.teams.destroy', teamId))
  }
}
</script>

<template>
  <Head title="Teams" />

  <AdminLayout>
    <div class="flex justify-between items-center mb-6">
      <div>
        <h1 class="text-3xl font-bold text-gray-900">🏢 Teams</h1>
        <p class="text-gray-600 mt-1">Manage game teams</p>
      </div>
      <Link
        :href="route('admin.teams.create')"
        class="px-4 py-2 btn-success"
      >
        ➕ Create Team
      </Link>
    </div>

    <form @submit.prevent class="mb-4 space-y-3 sm:space-y-0">
      <div class="flex flex-col sm:flex-row gap-2 items-start sm:items-center">
        <input v-model="q" placeholder="Search teams or owner" class="border rounded px-3 py-2 flex-1" @input="debouncedSearch" />
        <select v-model="perPage" class="border rounded px-2 py-2 w-full sm:w-auto">
          <option value="10">10</option>
          <option value="15">15</option>
          <option value="25">25</option>
          <option value="50">50</option>
        </select>
        <div class="flex gap-2 w-full sm:w-auto">
          <button type="button" @click="searchNow" class="flex-1 sm:flex-none px-3 py-2 btn-primary">Search</button>
          <Link :href="route('admin.teams.index')" class="flex-1 sm:flex-none px-3 py-2 border rounded text-center">Clear</Link>
        </div>
      </div>

      <!-- Bulk actions removed -->
    </form>

    <!-- Mobile Card View -->
    <div class="sm:hidden space-y-3">
      <div v-for="team in teams.data" :key="team.id" class="bg-white p-4 rounded-lg shadow border-l-4 border-blue-500">
        <div class="flex items-start justify-between gap-2 mb-2">
          <!-- multi-select removed -->
          <div class="flex items-center gap-3 flex-1">
            <img v-if="team.logo_url" :src="team.logo_url" :alt="team.name" class="w-12 h-12 rounded-full object-cover" />
            <div v-else class="w-12 h-12 rounded-full bg-gray-300 flex items-center justify-center text-gray-600 font-bold text-sm">
              {{ team.name.charAt(0) }}
            </div>
            <div>
              <p class="font-bold text-gray-900">#{{ team.id }}: {{ team.name }}</p>
              <p class="text-sm text-gray-600">Owner: {{ team.user?.name || '-' }}</p>
            </div>
          </div>
        </div>
        <div class="flex flex-col gap-2 mt-3 pt-3 border-t">
          <Link
            :href="route('admin.teams.selections.edit', team.id)"
            class="text-center px-3 py-2 text-sm bg-purple-100 text-purple-700 rounded hover:bg-purple-200"
          >
            Player Selections
          </Link>
          <Link
            :href="route('admin.teams.edit', team.id)"
            class="btn-primary btn-sm"
          >
            Edit
          </Link>
          <button
            @click="deleteTeam(team.id, team.name)"
            class="btn-danger btn-sm"
          >
            Delete
          </button>
        </div>
      </div>
      <div v-if="teams.data.length === 0" class="text-center py-8 text-gray-500">
        No teams found.
      </div>
    </div>

    <!-- Desktop Table View -->
    <div class="hidden sm:block bg-white shadow rounded-lg overflow-x-auto">
      <table class="w-full">
        <thead>
          <tr class="bg-gray-50 border-b border-gray-200">
            <th class="px-6 py-3 text-left text-xs font-semibold text-gray-700">Avatar</th>
            <th class="px-6 py-3 text-left text-xs font-semibold text-gray-700">Name</th>
            <th class="px-6 py-3 text-left text-xs font-semibold text-gray-700">Owner</th>
            <th class="px-6 py-3 text-center text-xs font-semibold text-gray-700">Actions</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-gray-200">
          <tr v-for="team in teams.data" :key="team.id" class="hover:bg-gray-50">
            <td class="px-6 py-4 text-sm">
              <img v-if="team.logo_url" :src="team.logo_url" :alt="team.name" class="w-12 h-12 rounded-full object-cover" />
              <div v-else class="w-12 h-12 rounded-full bg-gradient-to-br from-blue-400 to-blue-600 flex items-center justify-center text-white font-bold text-sm">
                {{ team.name.substring(0, 2).toUpperCase() }}
              </div>
            </td>
            <td class="px-6 py-4 text-sm">
              <p class="font-semibold text-gray-900">{{ team.name }}</p>
              <p class="text-xs text-gray-500">ID: {{ team.id }}</p>
            </td>
            <td class="px-6 py-4 text-sm text-gray-700">{{ team.user?.name || '-' }}</td>
            <td class="px-6 py-4 text-sm text-center">
              <div class="flex justify-center gap-2">
                <Link :href="route('admin.teams.selections.edit', team.id)" class="text-blue-600 hover:text-blue-800 font-semibold">Selections</Link>
                <Link :href="route('admin.teams.edit', team.id)" class="btn-primary btn-sm">Edit</Link>
                <button @click="deleteTeam(team.id, team.name)" class="btn-danger btn-sm">Delete</button>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    <div v-if="teams.data.length === 0" class="bg-white rounded-lg shadow p-8 text-center text-gray-500">
      <p class="text-lg">No teams found.</p>
    </div>

    <!-- Pagination -->
    <div class="flex justify-center mt-6 flex-wrap gap-2">
      <template v-for="link in teams.links" :key="link.label">
        <Link
          v-if="link.url"
          :href="link.url"
          class="px-3 py-1 rounded border text-sm"
          :class="{ 'bg-gray-800 text-white': link.active, 'hover:bg-gray-200': !link.active }"
          v-html="link.label"
        />
        <span v-else class="px-3 py-1 rounded border text-gray-400 text-sm" v-html="link.label" />
      </template>
    </div>

    <!-- Change owner modal removed along with bulk actions -->
  </AdminLayout>
</template>
