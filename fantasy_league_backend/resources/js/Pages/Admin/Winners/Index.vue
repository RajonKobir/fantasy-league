<script setup>
import { Head, Link, router } from '@inertiajs/vue3'
import AdminLayout from '@/Layouts/AdminLayout.vue'
import { ref } from 'vue'
import { Inertia } from '@inertiajs/inertia'
import { useDate } from '@/composables/useDate'

const props = defineProps({
  winners: Object,
  filters: Object,
})

const { formatDateShort } = useDate()

const q = ref(props.filters?.q || '')
const perPage = ref(props.filters?.per_page || 15)

let debounceTimer = null
function debouncedSearch() {
  clearTimeout(debounceTimer)
  debounceTimer = setTimeout(searchNow, 450)
}

function searchNow() {
  Inertia.get(route('admin.winners.index'), { q: q.value, per_page: perPage.value }, { preserveState: true, replace: true })
}

function deleteWinner(winnerId) {
  if (window.confirm('Delete this winner record? This action cannot be undone.')) {
    router.delete(route('admin.winners.destroy', winnerId))
  }
}
</script>

<template>
  <Head title="All Winners" />

  <AdminLayout>
    <div class="space-y-6">
      <!-- Header -->
      <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 class="text-3xl font-bold text-gray-900">🏅 All Winners</h1>
          <p class="text-gray-600 mt-1">View and manage all tournament winners</p>
        </div>
        <Link href="/admin/winners/manage" class="px-4 py-2 btn-success">
          ⚙️ Winners Management
        </Link>
      </div>

      <!-- Search and Filter -->
      <form @submit.prevent class="mb-4 space-y-3 sm:space-y-0">
        <div class="flex flex-col sm:flex-row gap-2 items-start sm:items-center">
          <input v-model="q" placeholder="Search by tournament name or user" class="border rounded px-3 py-2 flex-1" @input="debouncedSearch" />
          <select v-model="perPage" class="border rounded px-2 py-2 w-full sm:w-auto">
            <option value="10">10</option>
            <option value="15">15</option>
            <option value="25">25</option>
            <option value="50">50</option>
          </select>
          <div class="flex gap-2 w-full sm:w-auto">
            <button type="button" @click="searchNow" class="flex-1 sm:flex-none px-3 py-2 btn-primary">Search</button>
            <Link :href="route('admin.winners.index')" class="flex-1 sm:flex-none px-3 py-2 border rounded text-center">Clear</Link>
          </div>
        </div>
      </form>

      <!-- Mobile Card View -->
      <div class="sm:hidden space-y-3">
        <div v-for="winner in winners.data" :key="winner.id" class="bg-white p-4 rounded-lg shadow border-l-4 border-yellow-500">
          <div class="flex items-start justify-between">
            <div class="flex-1">
              <p class="font-bold text-gray-900">#{{ winner.id }}: {{ winner.tournament_name }}</p>
              <p class="text-sm text-gray-600">ID: {{ winner.tournament_id }}</p>
              <div class="mt-2">
                <span class="badge bg-blue-100 text-blue-800">{{ winner.user_names?.length || 0 }} winners</span>
                <span v-if="winner.status === 'active'" class="badge bg-green-100 text-green-800 ml-2">✅ Active</span>
                <span v-else class="badge bg-gray-100 text-gray-800 ml-2">⏸️ Inactive</span>
              </div>
            </div>
          </div>
          <div class="flex gap-2 pt-3 border-t mt-3">
            <Link :href="route('admin.winners.edit', winner.id)" class="btn-primary btn-sm">✏️ Edit</Link>
            <button type="button" @click="deleteWinner(winner.id)" class="btn-danger btn-sm">🗑️ Delete</button>
          </div>
        </div>
      </div>

      <!-- Winners Table -->
      <div class="bg-white rounded-xl shadow-lg overflow-hidden hover:shadow-xl transition-shadow">
        <div class="overflow-x-auto w-full">
          <table class="w-full">
            <thead>
              <tr class="bg-gray-50 border-b border-gray-200">
                <th class="px-6 py-3 text-left text-xs font-semibold text-gray-700">ID</th>
                <th class="px-6 py-3 text-left text-xs font-semibold text-gray-700">Tournament</th>
                <th class="px-6 py-3 text-left text-xs font-semibold text-gray-700">Winners</th>
                <th class="px-6 py-3 text-left text-xs font-semibold text-gray-700">Count</th>
                <th class="px-6 py-3 text-left text-xs font-semibold text-gray-700">Status</th>
                <th class="px-6 py-3 text-left text-xs font-semibold text-gray-700">Created</th>
                <th class="px-6 py-3 text-left text-xs font-semibold text-gray-700">Actions</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-200">
              <tr v-for="winner in winners.data" :key="winner.id" class="hover:bg-gray-50 transition-colors">
                <td class="px-6 py-4">
                  <span class="inline-flex items-center justify-center h-8 w-8 rounded-full bg-yellow-100 text-yellow-600 font-bold text-sm">
                    {{ winner.id }}
                  </span>
                </td>
                <td class="px-6 py-4">
                  <div class="flex items-center gap-2">
                    <span class="text-lg">🏆</span>
                    <div>
                      <p class="font-semibold text-gray-900">{{ winner.tournament_name }}</p>
                      <p class="text-xs text-gray-500">Tournament ID: {{ winner.tournament_id }}</p>
                    </div>
                  </div>
                </td>
                <td class="px-6 py-4">
                  <div class="space-y-1">
                    <div v-for="(name, idx) in winner.user_names" :key="idx" class="text-sm">
                      <span class="font-semibold text-gray-900">{{ idx + 1 }}. {{ name }}</span>
                      <span class="text-gray-500 text-xs ml-2">({{ winner.total_points[idx] }} pts)</span>
                    </div>
                  </div>
                </td>
                <td class="px-6 py-4">
                  <span class="badge bg-blue-100 text-blue-800">
                    {{ winner.user_names?.length || 0 }} winners
                  </span>
                </td>
                <td class="px-6 py-4">
                  <span v-if="winner.status === 'active'" class="badge bg-green-100 text-green-800">
                    ✅ Active
                  </span>
                  <span v-else class="badge bg-gray-100 text-gray-800">
                    ⏸️ Inactive
                  </span>
                </td>
                <td class="px-6 py-4">
                  <p class="text-sm text-gray-600">{{ formatDateShort(winner.created_at) }}</p>
                </td>
                <td class="px-6 py-4">
                  <div class="flex gap-2">
                    <Link :href="route('admin.winners.edit', winner.id)" class="btn-primary btn-sm">
                      ✏️ Edit
                    </Link>
                    <button type="button" @click="deleteWinner(winner.id)" class="btn-danger btn-sm">
                      🗑️ Delete
                    </button>
                  </div>
                </td>
              </tr>
              <tr v-if="winners.data.length === 0">
                <td colspan="6" class="px-6 py-12 text-center">
                  <div class="flex flex-col items-center gap-3 text-gray-500">
                    <span class="text-4xl">🏅</span>
                    <p class="text-lg font-semibold">No winners found</p>
                    <p class="text-sm">Try adjusting your search filters or visit <Link href="/admin/winners/manage" class="text-blue-600 hover:underline">Winners Management</Link> to create winners</p>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <!-- Pagination -->
      <div v-if="winners.data.length > 0" class="bg-white rounded-xl shadow-lg p-6">
        <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
          <p class="text-sm text-gray-600">
            Showing <span class="font-semibold">{{ winners.from }}</span> to <span class="font-semibold">{{ winners.to }}</span> of <span class="font-semibold">{{ winners.total }}</span> winner records
          </p>
          <div class="flex gap-2 flex-wrap">
            <Link
              v-for="link in winners.links"
              :key="link.label"
              :href="link.url || '#'"
              :class="{
                'bg-blue-600 text-white': link.active,
                'bg-gray-100 text-gray-700 hover:bg-gray-200': !link.active && link.url,
                'bg-gray-100 text-gray-400 cursor-not-allowed': !link.url
              }"
              :onclick="!link.url ? 'return false' : null"
              v-html="link.label"
              class="px-3 py-2 rounded-lg font-semibold transition-colors text-sm"
            />
          </div>
        </div>
      </div>
    </div>
  </AdminLayout>
</template>
