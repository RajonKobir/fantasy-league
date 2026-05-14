<script setup>
import { Head, Link, router } from '@inertiajs/vue3'
import AdminLayout from '@/Layouts/AdminLayout.vue'
import { ref } from 'vue'
import { Inertia } from '@inertiajs/inertia'

const props = defineProps({
  paymentMethods: Object,
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
  Inertia.get(route('admin.payment-methods.index'), { q: q.value, per_page: perPage.value }, { preserveState: true, replace: true })
}

function deletePaymentMethod(methodId) {
  if (window.confirm('Delete this payment method? This action cannot be undone.')) {
    router.delete(route('admin.payment-methods.destroy', methodId))
  }
}
</script>

<template>
  <Head title="Payment Methods" />

  <AdminLayout>
    <div class="space-y-6">
      <!-- Header -->
      <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 class="text-3xl font-bold text-gray-900">💳 Payment Methods</h1>
          <p class="text-gray-600 mt-1">Manage payment methods for requests</p>
        </div>
        <div class="flex gap-2">
          <Link href="/admin/payment-requests" class="px-4 py-2 bg-gray-200 text-gray-800 rounded-lg hover:bg-gray-300 transition-colors font-semibold">
            ⬅ Back
          </Link>
          <Link href="/admin/payment-methods/create" class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors font-semibold">
            ➕ Create Payment Method
          </Link>
        </div>
      </div>

      <!-- Search and Filter -->
      <form @submit.prevent class="mb-4 space-y-3 sm:space-y-0">
        <div class="flex flex-col sm:flex-row gap-2 items-start sm:items-center">
          <input v-model="q" placeholder="Search by name or code" class="border rounded px-3 py-2 flex-1" @input="debouncedSearch" />
          <select v-model="perPage" class="border rounded px-2 py-2 w-full sm:w-auto">
            <option value="10">10</option>
            <option value="15">15</option>
            <option value="25">25</option>
            <option value="50">50</option>
          </select>
          <div class="flex gap-2 w-full sm:w-auto">
            <button type="button" @click="searchNow" class="flex-1 sm:flex-none px-3 py-2 btn-primary">Search</button>
            <Link :href="route('admin.payment-methods.index')" class="flex-1 sm:flex-none px-3 py-2 border rounded text-center">Clear</Link>
          </div>
        </div>
      </form>

      <!-- Mobile Card View -->
      <div class="sm:hidden space-y-3">
        <div v-for="method in paymentMethods.data" :key="method.id" class="bg-white p-4 rounded-lg shadow border-l-4 border-blue-500">
          <div class="flex gap-3 items-start">
            <div class="flex-1">
              <p class="font-bold text-gray-900">{{ method.name }}</p>
              <p class="text-sm text-gray-600">Code: {{ method.code }}</p>
              <p class="text-sm text-gray-600">Sort order: {{ method.sort_order || '-' }}</p>
              <div class="mt-2">
                <span :class="[ 'badge', method.is_active ? 'bg-green-100 text-green-800' : 'bg-gray-100 text-gray-800' ]">{{ method.is_active ? '✅ Active' : '⏸️ Inactive' }}</span>
              </div>
            </div>
          </div>
          <div class="flex gap-2 pt-3 border-t mt-3">
            <Link :href="route('admin.payment-methods.edit', method.id)" class="btn-primary btn-sm">✏️ Edit</Link>
            <button type="button" @click="deletePaymentMethod(method.id)" class="btn-danger btn-sm">🗑️ Delete</button>
          </div>
        </div>
      </div>

      <!-- Payment Methods Table -->
      <div class="bg-white rounded-xl shadow-lg overflow-hidden hover:shadow-xl transition-shadow">
        <div class="overflow-x-auto w-full">
          <table class="w-full">
            <thead>
              <tr class="bg-gray-50 border-b border-gray-200">
                <th class="px-6 py-3 text-left text-xs font-semibold text-gray-700">Name</th>
                <th class="px-6 py-3 text-left text-xs font-semibold text-gray-700">Code</th>
                <th class="px-6 py-3 text-left text-xs font-semibold text-gray-700">Status</th>
                <th class="px-6 py-3 text-left text-xs font-semibold text-gray-700">Sort Order</th>
                <th class="px-6 py-3 text-left text-xs font-semibold text-gray-700">Actions</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-200">
              <tr v-for="method in paymentMethods.data" :key="method.id" class="hover:bg-gray-50 transition-colors">
                <td class="px-6 py-4 font-semibold text-gray-900">{{ method.name }}</td>
                <td class="px-6 py-4 text-gray-700">{{ method.code }}</td>
                <td class="px-6 py-4">
                  <span
                    :class="[
                      'badge',
                      method.is_active ? 'bg-green-100 text-green-800' : 'bg-gray-100 text-gray-800',
                    ]"
                  >
                    {{ method.is_active ? '✅ Active' : '⏸️ Inactive' }}
                  </span>
                </td>
                <td class="px-6 py-4 text-gray-700">{{ method.sort_order || '-' }}</td>
                <td class="px-6 py-4">
                  <div class="flex gap-2">
                    <Link
                      :href="route('admin.payment-methods.edit', method.id)"
                      class="btn-primary btn-sm"
                    >
                      ✏️ Edit
                    </Link>
                    <button type="button" @click="deletePaymentMethod(method.id)" class="btn-danger btn-sm">
                      🗑️ Delete
                    </button>
                  </div>
                </td>
              </tr>
              <tr v-if="paymentMethods.data.length === 0">
                <td colspan="5" class="px-6 py-12 text-center">
                  <div class="flex flex-col items-center gap-3 text-gray-500">
                    <span class="text-4xl">💳</span>
                    <p class="text-lg font-semibold">No payment methods found</p>
                    <p class="text-sm">Create one to get started</p>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <!-- Pagination -->
      <div class="bg-white rounded-xl shadow-lg p-6">
        <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
          <p class="text-sm text-gray-600">
            Showing <span class="font-semibold">{{ paymentMethods.from }}</span> to <span class="font-semibold">{{ paymentMethods.to }}</span> of <span class="font-semibold">{{ paymentMethods.total }}</span> payment methods
          </p>
          <div class="flex gap-2 flex-wrap">
            <Link
              v-for="link in paymentMethods.links"
              :key="link.label"
              :href="link.url || '#'"
              :onclick="!link.url ? 'return false' : null"
              :class="{
                'bg-blue-600 text-white': link.active,
                'bg-gray-100 text-gray-700 hover:bg-gray-200': !link.active && link.url,
                'bg-gray-100 text-gray-400 cursor-not-allowed': !link.url
              }"
              v-html="link.label"
              class="px-3 py-2 rounded-lg font-semibold transition-colors text-sm"
            />
          </div>
        </div>
      </div>
    </div>
  </AdminLayout>
</template>
