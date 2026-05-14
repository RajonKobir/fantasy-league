<script setup>
import { Head, Link, router } from '@inertiajs/vue3'
import AdminLayout from '@/Layouts/AdminLayout.vue'

defineProps({ roles: Object })

function deleteRole(roleId) {
  if (window.confirm('Delete this role? This action cannot be undone.')) {
    router.delete(`/admin/player-roles/${roleId}`)
  }
}
</script>

<template>
  <Head title="Player Roles" />

  <AdminLayout>
    <div class="space-y-6">
      <!-- Header -->
      <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 class="text-3xl font-bold text-gray-900">👥 Player Roles</h1>
          <p class="text-gray-600 mt-1">Manage player roles and positions</p>
        </div>
        <Link href="/admin/player-roles/create" class="px-4 py-2 btn-success">
          + Create Role
        </Link>
      </div>

      <!-- Roles Table -->
      <div v-if="!roles.data.length" class="bg-white shadow rounded-lg p-8 text-center">
        <p class="text-gray-500 text-lg">No player roles yet</p>
        <Link href="/admin/player-roles/create" class="mt-4 inline-block px-4 py-2 btn-primary">
          Create the first role
        </Link>
      </div>

      <!-- Mobile Card View -->
      <div class="sm:hidden space-y-3">
        <div v-for="role in roles.data" :key="role.id" class="bg-white p-4 rounded-lg shadow border-l-4 border-blue-500">
          <div>
            <p class="font-bold text-gray-900">{{ role.name }}</p>
            <p class="text-sm text-gray-600">{{ role.slug }}</p>
            <div class="mt-2">
              <span class="badge bg-blue-100 text-blue-800">{{ role.players_count }}</span>
            </div>
          </div>
          <div class="flex gap-2 pt-3 border-t mt-3">
            <Link :href="`/admin/player-roles/${role.id}/edit`" class="btn-primary btn-sm">✏️ Edit</Link>
            <button type="button" @click="deleteRole(role.id)" class="btn-danger btn-sm">🗑️ Delete</button>
          </div>
        </div>
      </div>

      <div v-if="roles.data.length" class="bg-white shadow rounded-lg">
        <div class="overflow-x-auto w-full">
          <table class="w-full">
            <thead class="bg-gray-50 border-b border-gray-200">
              <tr>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">#</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Name</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Slug</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Description</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Players</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-200">
            <tr v-for="(role, idx) in roles.data" :key="role.id" class="hover:bg-gray-50">
              <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">{{ idx + 1 }}</td>
              <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">{{ role.name }}</td>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-600 font-mono">{{ role.slug }}</td>
              <td class="px-6 py-4 text-sm text-gray-700">
                <span v-if="role.description" class="line-clamp-1">{{ role.description }}</span>
                <span v-else class="text-gray-400 italic">—</span>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-700">
                <span class="badge bg-blue-100 text-blue-800">
                  {{ role.players_count }}
                </span>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm font-medium space-x-3">
                <Link :href="`/admin/player-roles/${role.id}/edit`" class="btn-primary btn-sm">✏️ Edit</Link>
                <button type="button" @click="deleteRole(role.id)" class="btn-danger btn-sm">🗑️ Delete</button>
              </td>
            </tr>
          </tbody>
        </table>
        </div>

        <!-- Pagination -->
        <div v-if="roles.links.length > 3" class="px-6 py-4 border-t border-gray-200 flex gap-2">
          <Link
            v-for="link in roles.links"
            :key="link.label"
            :href="link.url || '#'"
            :onclick="!link.url ? 'return false' : null"
            class="px-3 py-1 text-sm rounded border"
            :class="link.active ? 'bg-blue-600 text-white border-blue-600' : 'border-gray-300 text-gray-700 hover:bg-gray-50'"
            v-html="link.label"
          />
        </div>
      </div>
    </div>
  </AdminLayout>
</template>
