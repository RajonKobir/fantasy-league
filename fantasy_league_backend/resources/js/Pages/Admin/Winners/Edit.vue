<script setup>
import { Head, Link, useForm } from '@inertiajs/vue3'
import AdminLayout from '@/Layouts/AdminLayout.vue'
import { ref } from 'vue'
import { useDate } from '@/composables/useDate'

const { formatDateShort } = useDate()

const props = defineProps({
  winner: Object,
})

const form = useForm({
  status: props.winner.status,
})

const submit = () => {
  form.put(route('admin.winners.update', props.winner.id), {
    onSuccess: () => {
      form.reset()
    },
  })
}
</script>

<template>
  <Head :title="`Edit Winner - ${winner.tournament_name}`" />

  <AdminLayout>
    <div class="space-y-6">
      <!-- Header -->
      <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 class="text-3xl font-bold text-gray-900">✏️ Edit Winner</h1>
          <p class="text-gray-600 mt-1">{{ winner.tournament_name }}</p>
        </div>
        <Link href="/admin/winners" class="px-4 py-2 bg-gray-200 text-gray-800 rounded-lg hover:bg-gray-300 transition-colors font-semibold">
          ⬅ Back
        </Link>
      </div>

      <!-- Winner Details -->
      <div class="bg-white rounded-xl shadow-lg p-6">
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <!-- Tournament Info -->
          <div>
            <label class="block text-sm font-semibold text-gray-700 mb-2">🏆 Tournament Name</label>
            <input
              type="text"
              :value="winner.tournament_name"
              disabled
              class="w-full px-4 py-2 border-2 border-gray-200 rounded-lg bg-gray-50 text-gray-600 cursor-not-allowed"
            />
          </div>

          <!-- Tournament ID -->
          <div>
            <label class="block text-sm font-semibold text-gray-700 mb-2">🆔 Tournament ID</label>
            <input
              type="text"
              :value="winner.tournament_id"
              disabled
              class="w-full px-4 py-2 border-2 border-gray-200 rounded-lg bg-gray-50 text-gray-600 cursor-not-allowed"
            />
          </div>

          <!-- Winners Count -->
          <div>
            <label class="block text-sm font-semibold text-gray-700 mb-2">👥 Number of Winners</label>
            <input
              type="text"
              :value="winner.user_names?.length || 0"
              disabled
              class="w-full px-4 py-2 border-2 border-gray-200 rounded-lg bg-gray-50 text-gray-600 cursor-not-allowed"
            />
          </div>

          <!-- Created Date -->
          <div>
            <label class="block text-sm font-semibold text-gray-700 mb-2">📅 Created Date</label>
            <input
              type="text"
              :value="formatDateShort(winner.created_at)"
              disabled
              class="w-full px-4 py-2 border-2 border-gray-200 rounded-lg bg-gray-50 text-gray-600 cursor-not-allowed"
            />
          </div>
        </div>
      </div>

      <!-- Status Update Form -->
      <form @submit.prevent="submit" class="bg-white rounded-xl shadow-lg p-6">
        <div class="space-y-6">
          <div>
            <label class="block text-sm font-semibold text-gray-700 mb-2">🏷️ Status</label>
            <select
              v-model="form.status"
              class="w-full px-4 py-2 border-2 border-gray-200 rounded-lg focus:border-blue-500 focus:outline-none transition-colors"
            >
              <option value="active">✅ Active (Visible in Flutter App)</option>
              <option value="inactive">⏸️ Inactive (Hidden from Flutter App)</option>
              <option value="cancel">❌ Cancel (Cancelled Tournament)</option>
              <option value="hold">⏳ Hold (Temporarily Hold Results)</option>
              <option value="archived">📦 Archived (Archived Results)</option>
            </select>
            <p class="text-xs text-gray-500 mt-2">
              Active: Visible in app | Inactive: Hidden | Cancel: Cancelled | Hold: Temporary hold | Archived: Historical records
            </p>
            <div v-if="form.errors.status" class="mt-2 text-sm text-red-600 font-semibold">
              {{ form.errors.status }}
            </div>
          </div>

          <!-- Winners List -->
          <div>
            <label class="block text-sm font-semibold text-gray-700 mb-3">🏅 Winners List</label>
            <div class="space-y-2 max-h-96 overflow-y-auto border-2 border-gray-200 rounded-lg p-4 bg-gray-50">
              <div v-for="(name, idx) in winner.user_names" :key="idx" class="flex items-center justify-between bg-white p-3 rounded-lg border border-gray-200 hover:border-blue-300 transition-colors">
                <div class="flex-1">
                  <p class="font-semibold text-gray-900">{{ idx + 1 }}. {{ name }}</p>
                  <p class="text-sm text-gray-600">Team: {{ winner.fantasy_teams_names[idx] }}</p>
                  <p class="text-sm text-gray-500">Points: {{ winner.total_points[idx] }}</p>
                </div>
                <span class="badge bg-yellow-100 text-yellow-800">
                  #{{ idx + 1 }}
                </span>
              </div>
            </div>
          </div>

          <!-- Form Actions -->
          <div class="flex gap-3 justify-end pt-4 border-t border-gray-200">
            <Link href="/admin/winners" class="px-6 py-2 border-2 border-gray-300 text-gray-700 rounded-lg hover:bg-gray-100 transition-colors font-semibold">
              Cancel
            </Link>
            <button
              type="submit"
              :disabled="form.processing"
              class="px-6 py-2 bg-gradient-to-r from-blue-600 to-blue-700 text-white rounded-lg hover:from-blue-700 hover:to-blue-800 transition-all font-semibold shadow-lg disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {{ form.processing ? '💾 Saving...' : '💾 Update Status' }}
            </button>
          </div>
        </div>
      </form>
    </div>
  </AdminLayout>
</template>
