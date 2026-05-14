<script setup>
import { usePage, Head, Link } from '@inertiajs/vue3'
import AdminLayout from '@/Layouts/AdminLayout.vue'
import { toast } from 'vue3-toastify'

const props = defineProps({ selections: Array })
const page = usePage()
if (page.props.flash?.success) toast.success(page.props.flash.success)
if (page.props.flash?.error) toast.error(page.props.flash.error)
</script>

<template>
  <Head title="Player Selections" />
  <AdminLayout>
    <div class="space-y-6">
      <!-- Header -->
      <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 class="text-3xl font-bold text-gray-900">👥 Player Selections</h1>
          <p class="text-gray-600 mt-1">Manage player selections for tournaments</p>
        </div>
        <Link href="/admin/player-selections/create" class="px-4 py-2 btn-success">
          + Add Selection
        </Link>
      </div>
      <!-- Mobile Card View -->
      <div class="sm:hidden space-y-3">
        <div v-for="sel in selections" :key="sel.id" class="bg-white p-4 rounded-lg shadow border-l-4 border-blue-500">
          <p class="font-bold text-gray-900">{{ sel.player?.name || '-' }}</p>
          <p class="text-sm text-gray-600">Team: {{ sel.team?.name || '-' }}</p>
          <div class="mt-2">
            <span class="badge" :class="sel.captain ? 'bg-green-100 text-green-800' : 'bg-gray-100 text-gray-800'">{{ sel.captain ? '✅ Captain' : '—' }}</span>
            <span class="badge ml-2" :class="sel.vice_captain ? 'bg-green-100 text-green-800' : 'bg-gray-100 text-gray-800'">{{ sel.vice_captain ? '✅ Vice' : '—' }}</span>
          </div>
          <div class="flex gap-2 pt-3 border-t mt-3">
            <Link :href="`/admin/player-selections/${sel.id}/edit`" class="btn-primary btn-sm">✏️ Edit</Link>
            <form :action="`/admin/player-selections/${sel.id}`" method="POST" class="inline">
              <input type="hidden" name="_method" value="DELETE">
              <input type="hidden" name="_token" :value="page.props.csrf_token">
              <button type="submit" class="btn-danger btn-sm" @click.prevent="confirm('Are you sure?') && $el.submit()">🗑️ Delete</button>
            </form>
          </div>
        </div>
        <div v-if="!selections || selections.length === 0" class="px-6 py-8 text-center text-gray-500">
          No selections found
        </div>
      </div>

      <!-- Table -->
      <div class="bg-white rounded-xl shadow-lg overflow-hidden">
        <div class="overflow-x-auto">
          <table class="w-full">
            <thead>
              <tr class="bg-gray-50 border-b border-gray-200">
                <th class="px-6 py-3 text-left text-xs font-semibold text-gray-700 uppercase tracking-wider">Team</th>
                <th class="px-6 py-3 text-left text-xs font-semibold text-gray-700 uppercase tracking-wider">Player</th>
                <th class="px-6 py-3 text-left text-xs font-semibold text-gray-700 uppercase tracking-wider">Captain</th>
                <th class="px-6 py-3 text-left text-xs font-semibold text-gray-700 uppercase tracking-wider">Vice-Captain</th>
                <th class="px-6 py-3 text-center text-xs font-semibold text-gray-700 uppercase tracking-wider">Actions</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-200">
              <tr v-for="sel in selections" :key="sel.id" class="hover:bg-gray-50 transition-colors">
                <td class="px-6 py-4 text-sm text-gray-900">{{ sel.team?.name || '-' }}</td>
                <td class="px-6 py-4 text-sm text-gray-900">{{ sel.player?.name || '-' }}</td>
                <td class="px-6 py-4 text-sm text-gray-900">{{ sel.captain ? '✅ Yes' : '❌ No' }}</td>
                <td class="px-6 py-4 text-sm text-gray-900">{{ sel.vice_captain ? '✅ Yes' : '❌ No' }}</td>
                <td class="px-6 py-4 text-sm text-center">
                  <div class="flex justify-center gap-2">
                    <Link :href="`/admin/player-selections/${sel.id}/edit`" class="btn-primary btn-sm">
                      ✏️ Edit
                    </Link>
                    <form :action="`/admin/player-selections/${sel.id}`" method="POST" class="inline">
                      <input type="hidden" name="_method" value="DELETE">
                      <input type="hidden" name="_token" :value="page.props.csrf_token">
                      <button type="submit" class="btn-danger btn-sm" @click.prevent="confirm('Are you sure?') && $el.submit()">🗑️ Delete</button>
                    </form>
                  </div>
                </td>
              </tr>
              <tr v-if="!selections || selections.length === 0">
                <td colspan="5" class="px-6 py-8 text-center text-gray-500">
                  No selections found
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  </AdminLayout>
</template>
