<template>
  <AdminLayout>
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <!-- Header -->
      <div class="mb-8">
        <h1 class="text-3xl font-bold text-gray-900">Cancel Requests</h1>
        <p class="text-gray-600 mt-2">Manage fantasy team cancellation requests and approvals</p>
      </div>

      <!-- Success Message -->
      <div v-if="$page.props.flash?.success" class="mb-4 p-4 bg-green-50 border border-green-200 rounded-lg">
        <p class="text-green-800">✓ {{ $page.props.flash.success }}</p>
      </div>

      <!-- Filters & Actions -->
      <form @submit.prevent class="mb-6 space-y-3 sm:space-y-0">
        <div class="flex flex-col sm:flex-row gap-2 items-start sm:items-center">
          <input v-model="q" placeholder="Search team or user..." class="border rounded px-3 py-2 flex-1" @input="debouncedSearch" />
          <select v-model="status" class="border rounded px-2 py-2 w-full sm:w-auto" @change="searchNow">
            <option value="">All Statuses</option>
            <option value="pending">Pending</option>
            <option value="approved">Approved</option>
            <option value="rejected">Rejected</option>
          </select>
          <div class="flex gap-2 w-full sm:w-auto">
            <button type="button" @click="searchNow" class="flex-1 sm:flex-none px-3 py-2 btn-primary">Search</button>
            <Link :href="route('admin.cancel-requests.index')" class="flex-1 sm:flex-none px-3 py-2 border rounded text-center">Clear</Link>
          </div>
        </div>
      </form>



      <!-- Table -->
      <div class="bg-white rounded-lg shadow-sm overflow-hidden">
        <table class="w-full">
          <thead class="bg-gray-50 border-b border-gray-200">
            <tr>
              <th class="px-6 py-3 text-left text-xs font-semibold text-gray-700">Team Name</th>
              <th class="px-6 py-3 text-left text-xs font-semibold text-gray-700">User</th>
              <th class="px-6 py-3 text-left text-xs font-semibold text-gray-700">Tournament</th>
              <th class="px-6 py-3 text-left text-xs font-semibold text-gray-700">Status</th>
              <th class="px-6 py-3 text-left text-xs font-semibold text-gray-700">Refund %</th>
              <th class="px-6 py-3 text-left text-xs font-semibold text-gray-700">Refund Amount</th>
              <th class="px-6 py-3 text-left text-xs font-semibold text-gray-700">Requested</th>
              <th class="px-6 py-3 text-right text-xs font-semibold text-gray-700">Actions</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-200">
            <tr v-for="request in cancelRequests?.data" :key="request?.id" class="hover:bg-gray-50">
              <td class="px-6 py-4 text-sm font-medium text-gray-900">
                {{ request.fantasy_team?.name || 'N/A' }}
              </td>
              <td class="px-6 py-4 text-sm text-gray-700">
                <div>{{ request.user?.name }}</div>
                <div class="text-xs text-gray-500">{{ request.user?.email }}</div>
              </td>
              <td class="px-6 py-4 text-sm text-gray-700">
                {{ request.tournament?.name || 'N/A' }}
              </td>
              <td class="px-6 py-4 text-sm">
                <span
                  :class="{
                    'bg-yellow-100 text-yellow-800': request.status === 'pending',
                    'bg-green-100 text-green-800': request.status === 'approved',
                    'bg-red-100 text-red-800': request.status === 'rejected',
                  }"
                  class="px-3 py-1 rounded-full text-xs font-semibold"
                >
                  {{ request.status.charAt(0).toUpperCase() + request.status.slice(1) }}
                </span>
              </td>
              <td class="px-6 py-4 text-sm text-gray-700">
                {{ parseFloat(request.refund_percentage_at_request || 0).toFixed(2) }}%
              </td>
              <td class="px-6 py-4 text-sm text-gray-900 font-medium">
                <span v-if="request.refund_amount">
                  {{ parseFloat(request.refund_amount).toFixed(2) }}
                </span>
                <span v-else class="text-gray-500">-</span>
              </td>
              <td class="px-6 py-4 text-sm text-gray-600">
                {{ formatDate(request.created_at) }}
              </td>
              <td class="px-6 py-4 text-sm text-right">
                <Link
                  :href="route('admin.cancel-requests.show', request.id)"
                  class="text-blue-600 hover:underline"
                >
                  View
                </Link>
              </td>
            </tr>

            <!-- Empty State -->
            <tr v-if="!cancelRequests?.data || cancelRequests?.data?.length === 0">
              <td colspan="8" class="px-6 py-12 text-center text-gray-500">
                <p>No cancel requests found.</p>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- Pagination -->
      <div v-if="cancelRequests?.links?.length" class="mt-6 flex justify-center">
        <div class="flex gap-2">
          <template v-for="(link, idx) in cancelRequests?.links" :key="idx">
            <Link
              v-if="link?.url"
              :href="link.url"
              :class="{
                'bg-blue-600 text-white': link?.active,
                'bg-white text-gray-700 border border-gray-300 hover:bg-gray-50': !link?.active,
              }"
              class="px-3 py-2 rounded-lg transition-colors text-sm"
              v-html="link?.label"
            />
          </template>
        </div>
      </div>
    </div>
  </AdminLayout>
</template>

<script setup>
import { ref } from 'vue'
import { Link, router } from '@inertiajs/vue3'
import AdminLayout from '@/Layouts/AdminLayout.vue'
import { Inertia } from '@inertiajs/inertia'
import { useDate } from '@/composables/useDate'

const { formatDate } = useDate()

const props = defineProps({
  cancelRequests: Object,
  statuses: Array,
  users: Array,
  tournaments: Array,
  filters: Object,
})

const q = ref(props.filters?.q || '')
const status = ref(props.filters?.status || '')
const perPage = ref(props.filters?.per_page || 15)

let debounceTimer = null
function debouncedSearch() {
  clearTimeout(debounceTimer)
  debounceTimer = setTimeout(searchNow, 450)
}

function searchNow() {
  Inertia.get(route('admin.cancel-requests.index'), { q: q.value, status: status.value, per_page: perPage.value }, { preserveState: true, replace: true })
}
</script>
