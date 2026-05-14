<script setup>
import { Head, Link, router } from '@inertiajs/vue3'
import AdminLayout from '@/Layouts/AdminLayout.vue'
import { ref } from 'vue'
import { Inertia } from '@inertiajs/inertia'
import { useDate } from '@/composables/useDate'

const props = defineProps({
  paymentRequests: Object,
  filters: Object,
})

const { formatDateShort } = useDate()

const q = ref(props.filters?.q || '')
const status = ref(props.filters?.status || 'pending')

let debounceTimer = null
function debouncedSearch() {
  clearTimeout(debounceTimer)
  debounceTimer = setTimeout(searchNow, 450)
}

function searchNow() {
  Inertia.get(route('admin.payment-requests.index'), { q: q.value, status: status.value }, { preserveState: true, replace: true })
}

const methodLabels = {
  bkash: 'bKash',
  rocket: 'Rocket',
  nagod: 'Nagod',
}

const statusLabels = {
  pending: 'Pending',
  approved: 'Approved',
  rejected: 'Rejected',
}

const statusColors = {
  pending: 'amber',
  approved: 'green',
  rejected: 'red',
}
</script>

<template>
  <Head title="Payment Requests" />

  <AdminLayout>
    <div class="space-y-6">
      <!-- Header -->
      <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 class="text-3xl font-bold text-gray-900">💳 Payment Requests</h1>
          <p class="text-gray-600 mt-1">Review and manage user payment requests</p>
        </div>
        <Link href="/admin/payment-requests/create" class="px-4 py-2 btn-success">
          + Create Request
        </Link>
      </div>

      <!-- Filters -->
      <form @submit.prevent class="mb-4 space-y-3 sm:space-y-0">
        <div class="flex flex-col sm:flex-row gap-2 items-start sm:items-center">
          <input v-model="q" placeholder="Search by name, email, or TrxID" class="border rounded px-3 py-2 flex-1" @input="debouncedSearch" />
          <select v-model="status" class="border rounded px-2 py-2 w-full sm:w-auto" @change="searchNow">
            <option value="pending">Pending</option>
            <option value="approved">Approved</option>
            <option value="rejected">Rejected</option>
            <option value="">All</option>
          </select>
          <div class="flex gap-2 w-full sm:w-auto">
            <button type="button" @click="searchNow" class="flex-1 sm:flex-none px-3 py-2 btn-primary">Search</button>
            <Link :href="route('admin.payment-requests.index')" class="flex-1 sm:flex-none px-3 py-2 border rounded text-center">Clear</Link>
          </div>
        </div>
      </form>

      <!-- Payment Requests Table -->
      <div class="bg-white rounded-xl shadow-lg overflow-hidden hover:shadow-xl transition-shadow">
        <!-- Mobile Card View -->
        <div class="sm:hidden divide-y divide-gray-200">
          <div v-for="request in paymentRequests.data" :key="request.id" class="p-4 hover:bg-blue-50 transition-colors">
            <div class="flex justify-between items-start gap-2 mb-3">
              <div>
                <p class="font-bold text-gray-900">#{{ request.id }}: {{ request.user.name }}</p>
                <p class="text-xs text-gray-500">{{ request.user.email }}</p>
              </div>
              <span :class="{
                'bg-amber-100 text-amber-800': request.status === 'pending',
                'bg-green-100 text-green-800': request.status === 'approved',
                'bg-red-100 text-red-800': request.status === 'rejected',
              }" class="badge whitespace-nowrap">
                <span v-if="request.status === 'pending'">⏳</span>
                <span v-if="request.status === 'approved'">✅</span>
                <span v-if="request.status === 'rejected'">❌</span>
                {{ statusLabels[request.status] }}
              </span>
            </div>
            <div class="space-y-2 text-sm mb-3">
              <div class="flex justify-between">
                <span class="text-gray-600">Amount:</span>
                <span class="font-bold">৳ {{ request.amount }}</span>
              </div>
              <div class="flex justify-between">
                <span class="text-gray-600">Method:</span>
                <span class="badge" :class="{
                  'bg-orange-100 text-orange-800': request.payment_method === 'bkash',
                  'bg-purple-100 text-purple-800': request.payment_method === 'rocket',
                  'bg-pink-100 text-pink-800': request.payment_method === 'nagod',
                }">
                  <span v-if="request.payment_method === 'bkash'">📱</span>
                  <span v-if="request.payment_method === 'rocket'">🚀</span>
                  <span v-if="request.payment_method === 'nagod'">💰</span>
                  {{ methodLabels[request.payment_method] }}
                </span>
              </div>
              <div class="flex justify-between">
                <span class="text-gray-600">TrxID:</span>
                <span class="font-mono text-xs">{{ request.transaction_number }}</span>
              </div>
              <div class="flex justify-between">
                <span class="text-gray-600">Date:</span>
                <span class="text-xs">{{ formatDateShort(request.created_at) }}</span>
              </div>
            </div>
            <Link
              :href="`/admin/payment-requests/${request.id}`"
              class="w-full block text-center px-3 py-2 bg-blue-100 text-blue-700 rounded-lg hover:bg-blue-200 transition-colors text-sm font-semibold"
            >
              View Details
            </Link>
          </div>
          <div v-if="paymentRequests.data.length === 0" class="px-6 py-12 text-center">
            <div class="flex flex-col items-center gap-3 text-gray-500">
              <span class="text-4xl">📭</span>
              <p class="text-lg font-semibold">No payment requests found</p>
              <p class="text-sm">Try adjusting your filters</p>
            </div>
          </div>
        </div>

        <!-- Desktop Table View -->
        <div class="hidden sm:block overflow-x-auto w-full">
          <table class="w-full">
            <thead>
              <tr class="bg-gray-50 border-b border-gray-200">
                <th class="px-6 py-3 text-left text-xs font-semibold text-gray-700">ID</th>
                <th class="px-6 py-3 text-left text-xs font-semibold text-gray-700">User</th>
                <th class="px-6 py-3 text-left text-xs font-semibold text-gray-700">Method</th>
                <th class="px-6 py-3 text-left text-xs font-semibold text-gray-700">Amount</th>
                <th class="px-6 py-3 text-left text-xs font-semibold text-gray-700">TrxID</th>
                <th class="px-6 py-3 text-left text-xs font-semibold text-gray-700">Status</th>
                <th class="px-6 py-3 text-left text-xs font-semibold text-gray-700">Date</th>
                <th class="px-6 py-3 text-left text-xs font-semibold text-gray-700">Actions</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-200">
              <tr v-for="request in paymentRequests.data" :key="request.id" class="hover:bg-gray-50 transition-colors">
                <td class="px-6 py-4">
                  <span class="inline-flex items-center justify-center h-8 w-8 rounded-full bg-blue-100 text-blue-600 font-bold text-sm">
                    {{ request.id }}
                  </span>
                </td>
                <td class="px-6 py-4">
                  <div>
                    <p class="font-semibold text-gray-900">{{ request.user.name }}</p>
                    <p class="text-xs text-gray-500">{{ request.user.email }}</p>
                  </div>
                </td>
                <td class="px-6 py-4">
                  <span class="badge" :class="{
                    'bg-orange-100 text-orange-800': request.payment_method === 'bkash',
                    'bg-purple-100 text-purple-800': request.payment_method === 'rocket',
                    'bg-pink-100 text-pink-800': request.payment_method === 'nagod',
                  }">
                    <span v-if="request.payment_method === 'bkash'">📱</span>
                    <span v-if="request.payment_method === 'rocket'">🚀</span>
                    <span v-if="request.payment_method === 'nagod'">💰</span>
                    {{ methodLabels[request.payment_method] }}
                  </span>
                </td>
                <td class="px-6 py-4">
                  <span class="font-bold text-gray-900">৳ {{ request.amount }}</span>
                </td>
                <td class="px-6 py-4">
                  <span class="font-mono text-xs text-gray-600">{{ request.transaction_number }}</span>
                </td>
                <td class="px-6 py-4">
                  <span :class="{
                    'bg-amber-100 text-amber-800': request.status === 'pending',
                    'bg-green-100 text-green-800': request.status === 'approved',
                    'bg-red-100 text-red-800': request.status === 'rejected',
                  }" class="badge">
                    <span v-if="request.status === 'pending'">⏳</span>
                    <span v-if="request.status === 'approved'">✅</span>
                    <span v-if="request.status === 'rejected'">❌</span>
                    {{ statusLabels[request.status] }}
                  </span>
                </td>
                <td class="px-6 py-4 text-sm text-gray-600">
                  {{ formatDateShort(request.created_at) }}
                </td>
                <td class="px-6 py-4">
                  <Link
                    :href="`/admin/payment-requests/${request.id}`"
                    class="btn-primary btn-sm"
                  >
                    👁️ View
                  </Link>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <!-- Pagination -->
      <div class="flex flex-col sm:flex-row items-start sm:items-center justify-between pt-4 gap-4">
        <p class="text-sm text-gray-600">
          Showing {{ paymentRequests.from || 0 }} to {{ paymentRequests.to || 0 }} of {{ paymentRequests.total }} requests
        </p>
        <div class="flex gap-2 w-full sm:w-auto">
          <Link
            v-if="paymentRequests.prev_page_url"
            :href="paymentRequests.prev_page_url"
            class="flex-1 sm:flex-none px-4 py-2 bg-gray-200 text-gray-800 rounded-lg hover:bg-gray-300 transition-colors font-semibold text-center"
          >
            ⬅ Previous
          </Link>
          <Link
            v-if="paymentRequests.next_page_url"
            :href="paymentRequests.next_page_url"
            class="flex-1 sm:flex-none px-4 py-2 btn-primary text-center"
          >
            Next ➡
          </Link>
        </div>
      </div>
    </div>
  </AdminLayout>
</template>
