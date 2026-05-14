<template>
  <AdminLayout>
    <Head title="Create Payment Request" />

    <div class="max-w-2xl mx-auto py-8">
      <!-- Breadcrumb -->
      <div class="mb-6">
        <Link href="/admin/payment-requests" class="text-blue-600 hover:underline">
          ← Payment Requests
        </Link>
      </div>

      <!-- Card Header -->
      <div class="bg-white shadow rounded-lg p-6 mb-6">
        <h1 class="text-3xl font-bold text-gray-900 mb-2">Create Payment Request</h1>
        <p class="text-gray-600">Manually create a payment request for a user</p>
      </div>

      <!-- Form Card -->
      <div class="bg-white shadow rounded-lg p-6">
        <form @submit.prevent="submitForm" class="space-y-6">
          <!-- User Selection -->
          <div>
            <label for="user_id" class="block text-sm font-medium text-gray-700 mb-2">
              User <span class="text-red-500">*</span>
            </label>
            <SearchableSelect
              id="user_id"
              v-model="form.user_id"
              :options="userOptions"
              placeholder="Search users by name or email..."
              name="user_id"
              :is-error="!!errors.user_id"
            />
            <p v-if="errors.user_id" class="mt-2 text-sm text-red-600">{{ errors.user_id[0] }}</p>
          </div>

          <!-- Payment Method -->
          <div>
            <label for="payment_method" class="block text-sm font-medium text-gray-700 mb-2">
              Payment Method <span class="text-red-500">*</span>
            </label>
            <select
              id="payment_method"
              v-model="form.payment_method"
              :class="[
                'w-full px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500',
                errors.payment_method ? 'border-red-500' : 'border-gray-300',
              ]"
            >
              <option value="">Select payment method</option>
              <option v-for="method in props.paymentMethods" :key="method.id" :value="method.code">
                {{ method.name }}
              </option>
            </select>
            <p v-if="errors.payment_method" class="mt-2 text-sm text-red-600">
              {{ errors.payment_method[0] }}
            </p>
            <p class="mt-1 text-xs text-gray-500">
              <Link href="/admin/payment-methods" class="text-blue-600 hover:underline">Manage payment methods</Link>
            </p>
          </div>

          <!-- Amount -->
          <div>
            <label for="amount" class="block text-sm font-medium text-gray-700 mb-2">
              Amount (৳) <span class="text-red-500">*</span>
            </label>
            <input
              id="amount"
              v-model="form.amount"
              type="number"
              min="100"
              max="100000"
              step="1"
              placeholder="100 - 100000"
              :class="[
                'w-full px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500',
                errors.amount ? 'border-red-500' : 'border-gray-300',
              ]"
            />
            <p v-if="errors.amount" class="mt-2 text-sm text-red-600">{{ errors.amount[0] }}</p>
          </div>

          <!-- To Number -->
          <div>
            <label for="to_number" class="block text-sm font-medium text-gray-700 mb-2">
              To Number <span class="text-red-500">*</span>
            </label>
            <input
              id="to_number"
              v-model="form.to_number"
              type="tel"
              placeholder="10-15 digits"
              :class="[
                'w-full px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500',
                errors.to_number ? 'border-red-500' : 'border-gray-300',
              ]"
            />
            <p v-if="errors.to_number" class="mt-2 text-sm text-red-600">{{ errors.to_number[0] }}</p>
          </div>

          <!-- From Number -->
          <div>
            <label for="from_number" class="block text-sm font-medium text-gray-700 mb-2">
              From Number <span class="text-red-500">*</span>
            </label>
            <input
              id="from_number"
              v-model="form.from_number"
              type="tel"
              placeholder="10-15 digits"
              :class="[
                'w-full px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500',
                errors.from_number ? 'border-red-500' : 'border-gray-300',
              ]"
            />
            <p v-if="errors.from_number" class="mt-2 text-sm text-red-600">{{ errors.from_number[0] }}</p>
          </div>

          <!-- Transaction Number -->
          <div>
            <label for="transaction_number" class="block text-sm font-medium text-gray-700 mb-2">
              Transaction Number <span class="text-red-500">*</span>
            </label>
            <input
              id="transaction_number"
              v-model="form.transaction_number"
              type="text"
              placeholder="e.g., TRX123456789"
              :class="[
                'w-full px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500',
                errors.transaction_number ? 'border-red-500' : 'border-gray-300',
              ]"
            />
            <p v-if="errors.transaction_number" class="mt-2 text-sm text-red-600">
              {{ errors.transaction_number[0] }}
            </p>
          </div>

          <!-- Form Actions -->
          <div class="flex gap-3 pt-6 border-t">
            <button
              type="submit"
              :disabled="isSubmitting"
              class="flex-1 px-6 py-2 btn-primary"
            >
              {{ isSubmitting ? 'Creating...' : 'Create Payment Request' }}
            </button>
            <Link
              href="/admin/payment-requests"
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
import { reactive, ref, computed } from 'vue'
import { useForm } from '@inertiajs/vue3'
import AdminLayout from '@/Layouts/AdminLayout.vue'
import SearchableSelect from '@/Components/SearchableSelect.vue'
import { Head, Link } from '@inertiajs/vue3'

const props = defineProps({
  users: {
    type: Array,
    required: true,
  },
  paymentMethods: {
    type: Array,
    required: true,
  },
})

const form = useForm({
  user_id: '',
  payment_method: '',
  to_number: '',
  from_number: '',
  amount: '',
  transaction_number: '',
})

const userOptions = computed(() => {
  return (props.users || []).map((user) => ({
    id: user.id,
    label: `${user.name} (${user.email})`,
  }))
})

const isSubmitting = ref(false)
const errors = reactive({})

const submitForm = async () => {
  isSubmitting.value = true
  errors.value = {}

  try {
    form.post(route('admin.payment-requests.store'), {
      onError: (err) => {
        Object.assign(errors, err)
      },
      onSuccess: () => {
        // Success handled by redirect
      },
      onFinish: () => {
        isSubmitting.value = false
      },
    })
  } catch (err) {
    // Handle form submission error
    isSubmitting.value = false
  }
}
</script>
