<script setup>
import { Head, Link } from '@inertiajs/vue3'
import { router } from '@inertiajs/vue3'
import AdminLayout from '@/Layouts/AdminLayout.vue'
import { ref } from 'vue'
import { Inertia } from '@inertiajs/inertia'

const props = defineProps({
  users: Object,
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
  Inertia.get(route('admin.users.index'), { q: q.value, per_page: perPage.value }, { preserveState: true, replace: true })
}

function deleteUser(userId) {
  if (window.confirm('Delete this user? This action cannot be undone.')) {
    router.delete(route('admin.users.destroy', userId))
  }
}
</script>

<template>
  <Head title="Users Management" />

  <AdminLayout>
    <div class="space-y-6">
      <!-- Header -->
      <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 class="text-3xl font-bold text-gray-900">👤 Users</h1>
          <p class="text-gray-600 mt-1">Manage regular system users</p>
        </div>
        <Link href="/admin/users/create" class="px-4 py-2 btn-success">
          ➕ Create User
        </Link>
      </div>

      <!-- Search and Filter -->
      <form @submit.prevent class="mb-4 space-y-3 sm:space-y-0">
        <div class="flex flex-col sm:flex-row gap-2 items-start sm:items-center">
          <input v-model="q" placeholder="Search by name or email" class="border rounded px-3 py-2 flex-1" @input="debouncedSearch" />
          <select v-model="perPage" class="border rounded px-2 py-2 w-full sm:w-auto">
            <option value="10">10</option>
            <option value="15">15</option>
            <option value="25">25</option>
            <option value="50">50</option>
          </select>
          <div class="flex gap-2 w-full sm:w-auto">
            <button type="button" @click="searchNow" class="flex-1 sm:flex-none px-3 py-2 btn-primary">Search</button>
            <Link :href="route('admin.users.index')" class="flex-1 sm:flex-none px-3 py-2 border rounded text-center">Clear</Link>
          </div>
        </div>
      </form>

      <!-- Mobile Card View -->
      <div class="sm:hidden space-y-3">
        <div v-for="user in users.data" :key="user.id" class="bg-white p-4 rounded-lg shadow border-l-4 border-blue-500">
          <div class="flex gap-3">
            <div class="flex-1">
              <p class="font-bold text-gray-900">#{{ user.id }}: {{ user.name }}</p>
              <p class="text-sm text-gray-600">{{ user.email }}</p>
              <div class="mt-2">
                <span v-if="user.is_admin" class="badge bg-purple-100 text-purple-800">👑 Admin</span>
                <span v-else class="badge bg-gray-100 text-gray-800">👤 User</span>
              </div>
            </div>
          </div>
          <div class="flex gap-2 pt-3 border-t mt-3">
            <Link :href="route('admin.users.edit', user.id)" class="btn-primary btn-sm">✏️ Edit</Link>
            <button type="button" @click="deleteUser(user.id)" class="btn-danger btn-sm">🗑️ Delete</button>
          </div>
        </div>
      </div>

      <!-- Users Table -->
      <div class="bg-white rounded-xl shadow-lg overflow-hidden">
        <div class="overflow-x-auto w-full">
          <table class="w-full">
            <thead>
              <tr class="bg-gray-50 border-b border-gray-200">
                <th class="px-6 py-3 text-left text-xs font-semibold text-gray-700">ID</th>
                <th class="px-6 py-3 text-left text-xs font-semibold text-gray-700">User</th>
                <th class="px-6 py-3 text-left text-xs font-semibold text-gray-700">Email</th>
                <th class="px-6 py-3 text-left text-xs font-semibold text-gray-700">Wallet</th>
                <th class="px-6 py-3 text-left text-xs font-semibold text-gray-700">Role</th>
                <th class="px-6 py-3 text-left text-xs font-semibold text-gray-700">Actions</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-200">
              <tr v-for="user in users.data" :key="user.id" class="hover:bg-gray-50">
                <td class="px-6 py-4">
                  <span class="inline-flex items-center justify-center h-8 w-8 rounded-full bg-blue-100 text-blue-600 font-bold text-sm">
                    {{ user.id }}
                  </span>
                </td>
                <td class="px-6 py-4">
                  <div class="flex items-center gap-3">
                    <img
                      v-if="user.avatar_url"
                      :src="user.avatar_url"
                      :alt="user.name"
                      class="h-10 w-10 rounded-full object-cover border-2 border-gray-200"
                    />
                    <div v-else class="h-10 w-10 rounded-full bg-gradient-to-br from-blue-400 to-blue-600 flex items-center justify-center text-white font-bold text-sm">
                      {{ user.name.charAt(0).toUpperCase() }}
                    </div>
                    <div>
                      <p class="font-semibold text-gray-900">{{ user.name }}</p>
                      <p class="text-xs text-gray-500">ID: {{ user.id }}</p>
                    </div>
                  </div>
                </td>
                <td class="px-6 py-4">
                  <p class="text-gray-700 break-all">{{ user.email }}</p>
                </td>
                <td class="px-6 py-4">
                  <span class="inline-block font-mono text-blue-700 bg-blue-50 rounded px-2 py-1 text-xs">
                    ৳{{ Number(user.wallet_balance).toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 }) }}
                  </span>
                </td>
                <td class="px-6 py-4">
                  <span v-if="user.is_admin" class="badge bg-purple-100 text-purple-800">
                    👑 Admin
                  </span>
                  <span v-else class="badge bg-gray-100 text-gray-800">
                    👤 User
                  </span>
                </td>
                <td class="px-6 py-4">
                  <div class="flex gap-2">
                    <Link
                      :href="route('admin.users.edit', user.id)"
                      class="btn-primary btn-sm"
                    >
                      ✏️ Edit
                    </Link>
                    <button
                      type="button"
                      @click="deleteUser(user.id)"
                      class="btn-danger btn-sm"
                    >
                      🗑️ Delete
                    </button>
                  </div>
                </td>
              </tr>
              <tr v-if="users.data.length === 0">
                <td colspan="5" class="px-6 py-12 text-center">
                  <div class="flex flex-col items-center gap-3 text-gray-500">
                    <span class="text-4xl">👤</span>
                    <p class="text-lg font-semibold">No users found</p>
                    <p class="text-sm">Try adjusting your search filters</p>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <!-- Pagination -->
      <div class="flex flex-col sm:flex-row items-start sm:items-center justify-between pt-4 gap-4">
        <p class="text-sm text-gray-600">
          Showing {{ users.from || 0 }} to {{ users.to || 0 }} of {{ users.total }} users
        </p>
        <div class="flex gap-2 w-full sm:w-auto">
          <Link
            v-if="users.prev_page_url"
            :href="users.prev_page_url"
            class="flex-1 sm:flex-none px-4 py-2 bg-gray-200 text-gray-800 rounded-lg hover:bg-gray-300 transition-colors font-semibold text-center"
          >
            ⬅ Previous
          </Link>
          <Link
            v-if="users.next_page_url"
            :href="users.next_page_url"
            class="flex-1 sm:flex-none px-4 py-2 btn-primary text-center"
          >
            Next ➡
          </Link>
        </div>
      </div>
    </div>
  </AdminLayout>
</template>
