<template>
  <AdminLayout>
    <Head title="Create Payment Method" />

    <div class="max-w-2xl mx-auto py-8">
      <!-- Breadcrumb -->
      <div class="mb-6">
        <Link href="/admin/payment-methods" class="text-blue-600 hover:underline">
          ← Payment Methods
        </Link>
      </div>

      <!-- Card Header -->
      <div class="bg-white shadow rounded-lg p-6 mb-6">
        <h1 class="text-3xl font-bold text-gray-900 mb-2">Create Payment Method</h1>
        <p class="text-gray-600">Add a new payment method for payment requests</p>
      </div>

      <!-- Form Card -->
      <div class="bg-white shadow rounded-lg p-6">
        <form @submit.prevent="submit" class="space-y-6">
          <!-- Name -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">
              Name <span class="text-red-500">*</span>
            </label>
            <input
              v-model="form.name"
              type="text"
              placeholder="e.g., bKash, Rocket, Nagod"
              :class="[
                'w-full px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500',
                form.errors.name ? 'border-red-500' : 'border-gray-300',
              ]"
            />
            <p v-if="form.errors.name" class="mt-2 text-sm text-red-600">{{ form.errors.name }}</p>
          </div>

          <!-- Code -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">
              Code <span class="text-red-500">*</span>
            </label>
            <input
              v-model="form.code"
              type="text"
              placeholder="e.g., bkash, rocket, nagod (lowercase)"
              :class="[
                'w-full px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500',
                form.errors.code ? 'border-red-500' : 'border-gray-300',
              ]"
            />
            <p v-if="form.errors.code" class="mt-2 text-sm text-red-600">{{ form.errors.code }}</p>
          </div>

          <!-- Description -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">Description</label>
            <textarea
              v-model="form.description"
              placeholder="Optional description for this payment method"
              rows="3"
              :class="[
                'w-full px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500',
                form.errors.description ? 'border-red-500' : 'border-gray-300',
              ]"
            />
            <p v-if="form.errors.description" class="mt-2 text-sm text-red-600">{{ form.errors.description }}</p>
          </div>

          <!-- Active Status -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">Status</label>
            <select
              v-model="form.is_active"
              :class="[
                'w-full px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500',
                form.errors.is_active ? 'border-red-500' : 'border-gray-300',
              ]"
            >
              <option :value="true">✅ Active</option>
              <option :value="false">⏸️ Inactive</option>
            </select>
            <p v-if="form.errors.is_active" class="mt-2 text-sm text-red-600">{{ form.errors.is_active }}</p>
          </div>

          <!-- Sort Order -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">Sort Order</label>
            <input
              v-model.number="form.sort_order"
              type="number"
              placeholder="0 (lower numbers appear first)"
              :class="[
                'w-full px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500',
                form.errors.sort_order ? 'border-red-500' : 'border-gray-300',
              ]"
            />
            <p v-if="form.errors.sort_order" class="mt-2 text-sm text-red-600">{{ form.errors.sort_order }}</p>
          </div>

          <!-- Form Actions -->
          <div class="flex gap-3 pt-6 border-t">
            <button
              type="submit"
              :disabled="form.processing"
              class="flex-1 px-6 py-2 bg-blue-600 text-white rounded-lg font-medium hover:bg-blue-700 transition disabled:opacity-50"
            >
              {{ form.processing ? 'Creating...' : 'Create Payment Method' }}
            </button>
            <Link
              href="/admin/payment-methods"
              class="flex-1 px-6 py-2 bg-gray-200 text-gray-700 rounded-lg font-medium hover:bg-gray-300 text-center transition"
            >
              Cancel
            </Link>
          </div>
        </form>
      </div>
    </div>
  </AdminLayout>
</template>

<script setup>
import { Head, Link, useForm } from '@inertiajs/vue3'
import AdminLayout from '@/Layouts/AdminLayout.vue'

const form = useForm({
  name: '',
  code: '',
  description: '',
  is_active: true,
  sort_order: 0,
})

const submit = () => {
  form.post(route('admin.payment-methods.store'))
}
</script>
