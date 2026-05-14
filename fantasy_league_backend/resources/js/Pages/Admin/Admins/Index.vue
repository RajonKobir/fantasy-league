<script setup>
import { Head, Link } from '@inertiajs/vue3'
import { router } from '@inertiajs/vue3'
import AdminLayout from '@/Layouts/AdminLayout.vue'
import { ref } from 'vue'
import { Inertia } from '@inertiajs/inertia'

const props = defineProps({
  admins: Object,
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
  Inertia.get(route('admin.admins.index'), { q: q.value, per_page: perPage.value }, { preserveState: true, replace: true })
}

function deleteAdmin(adminId) {
  if (window.confirm('Delete this admin? This action cannot be undone.')) {
    router.delete(route('admin.admins.destroy', adminId))
  }
}
</script>

<template>
  <Head title="Admins Management" />

  <AdminLayout>
    <div class="space-y-6">
      <!-- Header -->
      <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 class="text-3xl font-bold text-gray-900">👑 Admins</h1>
          <p class="text-gray-600 mt-1">Manage system administrators</p>
        </div>
        <Link href="/admin/admins/create" class="px-4 py-2 btn-success">
          ➕ Create Admin
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
            <Link :href="route('admin.admins.index')" class="flex-1 sm:flex-none px-3 py-2 border rounded text-center">Clear</Link>
          </div>
        </div>
      </form>

      <!-- Mobile Card View -->
      <div class="sm:hidden space-y-3">
        <div v-for="admin in admins.data" :key="admin.id" class="bg-white p-4 rounded-lg shadow border-l-4 border-purple-500">
          <div class="flex gap-3">
            <div class="flex-1">
              <p class="font-bold text-gray-900">#{{ admin.id }}: {{ admin.name }}</p>
              <p class="text-sm text-gray-600 mt-1">{{ admin.email }}</p>
              <div class="mt-2">
                <span class="badge bg-purple-100 text-purple-800">👑 Admin</span>
              </div>
            </div>
          </div>
          <div class="flex gap-2 pt-3 border-t mt-3">
            <Link :href="route('admin.admins.edit', admin.id)" class="btn-primary btn-sm">✏️ Edit</Link>
            <button type="button" @click="deleteAdmin(admin.id)" class="btn-danger btn-sm">🗑️ Delete</button>
          </div>
        </div>
      </div>

      <!-- Admins Table -->
      <div class="bg-white rounded-xl shadow-lg overflow-hidden hover:shadow-xl transition-shadow">
        <div class="overflow-x-auto w-full">
          <table class="w-full">
            <thead>
              <tr class="bg-gray-50 border-b border-gray-200">
                <th class="px-6 py-3 text-left text-xs font-semibold text-gray-700">ID</th>
                <th class="px-6 py-3 text-left text-xs font-semibold text-gray-700">Admin</th>
                <th class="px-6 py-3 text-left text-xs font-semibold text-gray-700">Email</th>
                <th class="px-6 py-3 text-left text-xs font-semibold text-gray-700">Status</th>
                <th class="px-6 py-3 text-left text-xs font-semibold text-gray-700">Actions</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-200">
              <tr v-for="admin in admins.data" :key="admin.id" class="hover:bg-gray-50 transition-colors">
                <td class="px-6 py-4">
                  <span class="inline-flex items-center justify-center h-8 w-8 rounded-full bg-purple-100 text-purple-600 font-bold text-sm">
                    {{ admin.id }}
                  </span>
                </td>
                <td class="px-6 py-4">
                  <div class="flex items-center gap-3">
                    <img
                      v-if="admin.avatar_url"
                      :src="admin.avatar_url"
                      :alt="admin.name"
                      class="h-10 w-10 rounded-full object-cover border-2 border-gray-200"
                    />
                    <div v-else class="h-10 w-10 rounded-full bg-gradient-to-br from-purple-400 to-purple-600 flex items-center justify-center text-white font-bold text-sm">
                      {{ admin.name.charAt(0).toUpperCase() }}
                    </div>
                    <div>
                      <p class="font-semibold text-gray-900">{{ admin.name }}</p>
                      <p class="text-xs text-gray-500">ID: {{ admin.id }}</p>
                    </div>
                  </div>
                </td>
                <td class="px-6 py-4">
                  <p class="text-gray-700 break-all">{{ admin.email }}</p>
                </td>
                <td class="px-6 py-4">
                  <span class="badge bg-purple-100 text-purple-800">
                    👑 Admin
                  </span>
                </td>
                <td class="px-6 py-4">
                  <div class="flex gap-2">
                    <Link
                      :href="route('admin.admins.edit', admin.id)"
                      class="btn-primary btn-sm"
                    >
                      ✏️ Edit
                    </Link>
                    <button
                      type="button"
                      @click="deleteAdmin(admin.id)"
                      class="btn-danger btn-sm"
                    >
                      🗑️ Delete
                    </button>
                  </div>
                </td>
              </tr>
              <tr v-if="admins.data.length === 0">
                <td colspan="5" class="px-6 py-12 text-center">
                  <div class="flex flex-col items-center gap-3 text-gray-500">
                    <span class="text-4xl">👑</span>
                    <p class="text-lg font-semibold">No admins found</p>
                    <p class="text-sm">Try adjusting your search filters</p>
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
            Showing <span class="font-semibold">{{ admins.from }}</span> to <span class="font-semibold">{{ admins.to }}</span> of <span class="font-semibold">{{ admins.total }}</span> admins
          </p>
          <div class="flex gap-2 flex-wrap">
            <Link
              v-for="link in admins.links"
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
