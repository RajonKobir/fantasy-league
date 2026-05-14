<script setup>
import { Head, Link, router } from '@inertiajs/vue3'
import AdminLayout from '@/Layouts/AdminLayout.vue'
import { ref } from 'vue'
import { Inertia } from '@inertiajs/inertia'
import { useDate } from '@/composables/useDate'

const props = defineProps({
  tournaments: Object,
  filters: Object,
})

const { formatDate } = useDate()

const q = ref(props.filters?.q || '')
const perPage = ref(props.filters?.per_page || 15)

let debounceTimer = null
function debouncedSearch() {
  clearTimeout(debounceTimer)
  debounceTimer = setTimeout(searchNow, 450)
}

function searchNow() {
  Inertia.get(route('admin.tournaments.index'), { q: q.value, per_page: perPage.value }, { preserveState: true, replace: true })
}

function deleteTournament(tournamentId) {
  if (window.confirm('Delete this tournament? This action cannot be undone.')) {
    router.delete(route('admin.tournaments.destroy', tournamentId))
  }
}
</script>

<template>
  <Head title="Tournaments" />

  <AdminLayout>
    <!-- Header -->
    <div class="flex flex-col gap-4 mb-6">
      <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 class="text-2xl sm:text-3xl font-bold text-gray-900">🏆 Tournaments</h1>
          <p class="text-sm sm:text-base text-gray-600 mt-1">Manage game tournaments</p>
        </div>
        <Link href="/admin/tournaments/create" class="px-4 py-2 btn-success text-center">
          + Create Tournament
        </Link>
      </div>
    </div>

    <!-- Search & Filter Section -->
    <form @submit.prevent class="mb-6 bg-white rounded-lg p-4 shadow-sm border space-y-3">
      <div class="flex flex-col sm:flex-row gap-2 sm:gap-3 items-stretch sm:items-center">
        <input
          v-model="q"
          placeholder="Search tournaments..."
          class="border rounded px-3 py-2 text-sm flex-1"
          @input="debouncedSearch"
        />
        <select
          v-model="perPage"
          class="border rounded px-3 py-2 text-sm"
        >
          <option value="10">10/page</option>
          <option value="15">15/page</option>
          <option value="25">25/page</option>
          <option value="50">50/page</option>
        </select>
      </div>
      <div class="flex gap-2 text-sm">
        <button type="button" @click="searchNow" class="flex-1 sm:flex-none px-4 py-2 btn-primary text-sm">
          🔍 Search
        </button>
        <Link :href="route('admin.tournaments.index')" class="flex-1 sm:flex-none px-4 py-2 border rounded text-center text-sm hover:bg-gray-50">
          Clear
        </Link>
      </div>
    </form>

    <!-- Mobile Card View -->
    <div class="md:hidden space-y-3">
      <div v-for="t in tournaments.data" :key="t.id" class="bg-white p-4 rounded-lg shadow border-l-4 border-blue-500">
        <div class="flex items-start gap-3 mb-3">
          <div class="flex-shrink-0">
            <img v-if="t.logo_url" :src="t.logo_url" alt="avatar" class="h-12 w-12 object-cover rounded-lg border" />
            <span v-else class="h-12 w-12 rounded-lg bg-gray-200 text-gray-400 flex items-center justify-center text-lg">—</span>
          </div>
          <div class="flex-1 min-w-0">
            <p class="font-bold text-gray-900 text-sm">{{ t.name }}</p>
            <p class="text-xs text-gray-600 mt-1">#{{ t.id }}</p>
          </div>
          <div class="flex-shrink-0">
            <span
              v-if="t.status === 'active'"
              class="inline-block px-2.5 py-1 bg-green-100 text-green-800 text-xs font-medium rounded-full"
            >Active</span>
            <span
              v-else-if="t.status === 'running'"
              class="inline-block px-2.5 py-1 bg-blue-100 text-blue-800 text-xs font-medium rounded-full"
            >Running</span>
            <span
              v-else-if="t.status === 'upcoming'"
              class="inline-block px-2.5 py-1 bg-yellow-100 text-yellow-800 text-xs font-medium rounded-full"
            >Upcoming</span>
            <span
              v-else-if="t.status === 'stopped'"
              class="inline-block px-2.5 py-1 bg-gray-100 text-gray-800 text-xs font-medium rounded-full"
            >Stopped</span>
            <span
              v-else-if="t.status === 'canceled'"
              class="inline-block px-2.5 py-1 bg-red-100 text-red-800 text-xs font-medium rounded-full"
            >Canceled</span>
            <span
              v-else
              class="inline-block px-2.5 py-1 bg-gray-100 text-gray-800 text-xs font-medium rounded-full"
            >{{ t.status }}</span>
          </div>
        </div>

        <div class="grid grid-cols-2 gap-2 text-xs mb-3 pb-3 border-b">
          <div>
            <p class="text-gray-600">Start Date</p>
            <p class="font-semibold text-gray-900">{{ formatDate(t.start_at) }}</p>
          </div>
          <div>
            <p class="text-gray-600">End Date</p>
            <p class="font-semibold text-gray-900">{{ formatDate(t.end_at) }}</p>
          </div>
          <div>
            <p class="text-gray-600">Fee</p>
            <p class="font-semibold text-gray-900">{{ t.entry_fee }}</p>
          </div>
        </div>

        <div class="flex gap-2 pt-2">
          <Link :href="route('admin.tournaments.edit', t.id)" class="flex-1 px-3 py-2 btn-primary btn-sm text-center text-xs">
            ✏️ Edit
          </Link>
          <button type="button" @click="deleteTournament(t.id)" class="flex-1 px-3 py-2 btn-danger btn-sm text-xs">
            🗑️ Delete
          </button>
        </div>
      </div>
      <div v-if="tournaments.data.length === 0" class="text-center py-8 text-gray-500 bg-white rounded-lg">
        No tournaments found.
      </div>
    </div>

    <!-- Desktop Table View -->
    <div class="hidden md:block bg-white shadow rounded-lg overflow-x-auto">
      <table class="w-full text-sm">
        <thead class="bg-gray-50 border-b border-gray-200">
          <tr class="text-left">
            <th class="px-4 lg:px-6 py-3 font-semibold text-gray-700 whitespace-nowrap">ID</th>
            <th class="px-4 lg:px-6 py-3 font-semibold text-gray-700 whitespace-nowrap">Avatar</th>
            <th class="px-4 lg:px-6 py-3 font-semibold text-gray-700">Name</th>
            <th class="px-4 lg:px-6 py-3 font-semibold text-gray-700 whitespace-nowrap">Start</th>
            <th class="px-4 lg:px-6 py-3 font-semibold text-gray-700 whitespace-nowrap">End</th>
            <th class="px-4 lg:px-6 py-3 font-semibold text-gray-700 whitespace-nowrap">Status</th>
            <th class="px-4 lg:px-6 py-3 font-semibold text-gray-700 whitespace-nowrap">Fee</th>
            <th class="px-4 lg:px-6 py-3 text-center font-semibold text-gray-700">Actions</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-gray-200">
          <tr v-for="t in tournaments.data" :key="t.id" class="hover:bg-gray-50 transition">
            <td class="px-4 lg:px-6 py-4 text-sm">{{ t.id }}</td>
            <td class="px-4 lg:px-6 py-4 text-sm">
              <img v-if="t.logo_url" :src="t.logo_url" alt="avatar" class="h-10 w-10 object-cover rounded-lg border" />
              <span v-else class="h-10 w-10 rounded-lg bg-gray-200 text-gray-400 flex items-center justify-center">—</span>
            </td>
            <td class="px-4 lg:px-6 py-4 text-sm font-medium text-gray-900">{{ t.name }}</td>
            <td class="px-4 lg:px-6 py-4 text-sm whitespace-nowrap text-gray-600">{{ formatDate(t.start_at) }}</td>
            <td class="px-4 lg:px-6 py-4 text-sm whitespace-nowrap text-gray-600">{{ formatDate(t.end_at) }}</td>
            <td class="px-4 lg:px-6 py-4 text-sm whitespace-nowrap">
              <span
                v-if="t.status === 'active'"
                class="inline-block px-2 py-1 bg-green-100 text-green-800 text-xs font-medium rounded"
              >Active</span>
              <span
                v-else-if="t.status === 'running'"
                class="inline-block px-2 py-1 bg-blue-100 text-blue-800 text-xs font-medium rounded"
              >Running</span>
              <span
                v-else-if="t.status === 'upcoming'"
                class="inline-block px-2 py-1 bg-yellow-100 text-yellow-800 text-xs font-medium rounded"
              >Upcoming</span>
              <span
                v-else-if="t.status === 'stopped'"
                class="inline-block px-2 py-1 bg-gray-100 text-gray-800 text-xs font-medium rounded"
              >Stopped</span>
              <span
                v-else-if="t.status === 'canceled'"
                class="inline-block px-2 py-1 bg-red-100 text-red-800 text-xs font-medium rounded"
              >Canceled</span>
              <span
                v-else
                class="inline-block px-2 py-1 bg-gray-100 text-gray-800 text-xs font-medium rounded"
              >{{ t.status }}</span>
            </td>
            <td class="px-4 lg:px-6 py-4 text-sm whitespace-nowrap text-gray-900 font-medium">{{ t.entry_fee }}</td>
            <td class="px-4 lg:px-6 py-4">
              <div class="flex gap-2 justify-center">
                <Link :href="route('admin.tournaments.edit', t.id)" class="px-3 py-2 btn-primary btn-sm text-xs">
                  ✏️ Edit
                </Link>
                <button type="button" @click="deleteTournament(t.id)" class="px-3 py-2 btn-danger btn-sm text-xs">
                  🗑️ Delete
                </button>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Pagination -->
    <div class="mt-6 flex flex-col sm:flex-row gap-2 items-center justify-center">
      <Link
        v-if="tournaments.prev_page_url"
        :href="tournaments.prev_page_url"
        class="px-4 py-2 border rounded text-sm hover:bg-gray-50"
      >
        ← Prev
      </Link>
      <span class="text-sm text-gray-600">
        Page {{ tournaments.current_page }} of {{ tournaments.last_page }}
      </span>
      <Link
        v-if="tournaments.next_page_url"
        :href="tournaments.next_page_url"
        class="px-4 py-2 border rounded text-sm hover:bg-gray-50"
      >
        Next →
      </Link>
    </div>
  </AdminLayout>
</template>
