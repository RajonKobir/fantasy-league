<script setup>
import { Head, Link, useForm } from '@inertiajs/vue3'
import { ref, computed } from 'vue'
import AdminLayout from '@/Layouts/AdminLayout.vue'

defineOptions({
  layout: AdminLayout,
})

const { playerRole } = defineProps({ playerRole: Object })

const form = useForm({ name: playerRole.name, description: playerRole.description })
const errors = ref({})
const isSubmitting = ref(false)

const hasChanges = computed(() => {
  return form.name !== playerRole.name || form.description !== playerRole.description
})

function submit() {
  errors.value = {}

  if (!form.name.trim()) {
    errors.value.name = 'Role name is required'
    return
  }

  isSubmitting.value = true
  form.put(route('admin.player-roles.update', playerRole.id), {
    onError: (err) => {
      Object.assign(errors.value, err)
    },
    onFinish: () => {
      isSubmitting.value = false
    },
  })
}
</script>

<template>
  <Head :title="`Edit ${playerRole.name}`" />

  <div class="max-w-2xl mx-auto py-8">
      <!-- Breadcrumb -->
      <div class="mb-6">
        <Link href="/admin/player-roles" class="text-blue-600 hover:underline">
          ← Player Roles
        </Link>
      </div>

      <!-- Card Header -->
      <div class="bg-white shadow rounded-lg p-6 mb-6">
        <h1 class="text-3xl font-bold text-gray-900 mb-2">Edit Player Role</h1>
        <p class="text-gray-600">Update role information</p>
      </div>

      <!-- Form Card -->
      <div class="bg-white shadow rounded-lg p-6">
        <form @submit.prevent="submit" class="space-y-6">
          <!-- Role Name -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">
              Role Name <span class="text-red-500">*</span>
            </label>
            <input
              v-model="form.name"
              type="text"
              placeholder="e.g., Batsman, Bowler, All-rounder"
              :class="[
                'w-full px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500',
                errors.name ? 'border-red-500' : 'border-gray-300',
              ]"
            />
            <p v-if="errors.name" class="mt-2 text-sm text-red-600">{{ errors.name }}</p>
          </div>

          <!-- Description -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">Description</label>
            <textarea
              v-model="form.description"
              rows="4"
              placeholder="Optional description for this role"
              class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>

          <!-- Form Actions -->
          <div class="flex gap-3 pt-6 border-t">
            <button
              type="submit"
              :disabled="!hasChanges || isSubmitting"
              class="flex-1 px-6 py-2 bg-blue-600 text-white rounded-lg font-medium hover:bg-blue-700 transition disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {{ isSubmitting ? 'Saving...' : 'Update Role' }}
            </button>
            <Link
              href="/admin/player-roles"
              class="flex-1 px-6 py-2 bg-gray-200 text-gray-700 rounded-lg font-medium hover:bg-gray-300 text-center transition"
            >
              Cancel
            </Link>
          </div>
        </form>
      </div>
    </div>
</template>
