<script setup>
import { Head, useForm } from '@inertiajs/vue3'
import AdminLayout from '@/Layouts/AdminLayout.vue'
import { computed, ref } from 'vue'
import { useDate } from '@/composables/useDate'

const { formatDate } = useDate()

const props = defineProps({
  paymentRequest: {
    type: Object,
    required: true,
  },
})

const showError = ref(false)
const errorMessage = ref('')

const methodLabels = {
  bkash: 'bKash',
  rocket: 'Rocket',
  nagod: 'Nagod',
}

const form = useForm({
  admin_notes: props.paymentRequest?.admin_notes || '',
})

const isApproved = computed(() => props.paymentRequest?.status === 'approved')
const isRejected = computed(() => props.paymentRequest?.status === 'rejected')
const isPending = computed(() => props.paymentRequest?.status === 'pending')

const approveRequest = async () => {
  if (!confirm(`Approve ৳${props.paymentRequest.amount} payment request from ${props.paymentRequest.user.name}?`)) {
    return
  }

  form.post(route('admin.payment-requests.approve', props.paymentRequest.id), {
    onSuccess: () => {
      window.location.reload()
    },
    onError: (errors) => {
      // Handle approval error
      errorMessage.value = Object.values(errors).flat().join(', ') || 'Failed to approve payment request'
      showError.value = true
    }
  })
}

const rejectRequest = async () => {
  const reason = prompt('Enter rejection reason:')
  if (!reason) {
    return
  }

  const rejectForm = useForm({
    admin_notes: reason,
  })

  rejectForm.post(route('admin.payment-requests.reject', props.paymentRequest.id), {
    onSuccess: () => {
      window.location.reload()
    },
    onError: (errors) => {
      // Handle rejection error
      errorMessage.value = Object.values(errors).flat().join(', ') || 'Failed to reject payment request'
      showError.value = true
    }
  })
}
</script>

<template>
  <Head :title="`Payment Request #${props.paymentRequest.id}`" />

  <AdminLayout>
    <div class="space-y-6">
      <!-- Error Alert -->
      <div v-if="showError" class="p-4 bg-red-100 border border-red-400 text-red-700 rounded-lg">
        <p class="font-bold">Error</p>
        <p class="text-sm">{{ errorMessage }}</p>
        <button @click="showError = false" class="text-sm mt-2 underline">Dismiss</button>
      </div>

      <!-- Header -->
      <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 class="text-3xl font-bold text-gray-900">💳 Payment Request #{{ props.paymentRequest.id }}</h1>
          <p class="text-gray-600 mt-1">Review and manage this payment request</p>
        </div>
        <div>
          <a href="/admin/payment-requests" class="px-4 py-2 bg-gray-200 text-gray-800 rounded-lg hover:bg-gray-300 transition-colors font-semibold">
            ⬅ Back
          </a>
        </div>
      </div>

      <!-- Status Card -->
      <div class="bg-gradient-to-r from-blue-600 to-blue-700 text-white rounded-xl shadow-lg p-6">
        <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
          <div>
            <p class="text-blue-200 text-sm">Amount</p>
            <p class="text-3xl font-bold">৳ {{ props.paymentRequest.amount }}</p>
          </div>
          <div>
            <p class="text-blue-200 text-sm">Payment Method</p>
            <p class="text-2xl font-bold flex items-center gap-2">
              <span v-if="props.paymentRequest.payment_method === 'bkash'">📱</span>
              <span v-if="props.paymentRequest.payment_method === 'rocket'">🚀</span>
              <span v-if="props.paymentRequest.payment_method === 'nagod'">💰</span>
              {{ methodLabels[props.paymentRequest.payment_method] }}
            </p>
          </div>
          <div>
            <p class="text-blue-200 text-sm">Status</p>
            <p :class="{
              'text-yellow-300': isPending,
              'text-green-300': isApproved,
              'text-red-300': isRejected,
            }" class="text-2xl font-bold flex items-center gap-2">
              <span v-if="isPending">⏳</span>
              <span v-if="isApproved">✅</span>
              <span v-if="isRejected">❌</span>
              {{ props.paymentRequest.status.toUpperCase() }}
            </p>
          </div>
        </div>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <!-- User Information -->
        <div class="lg:col-span-2 space-y-6">
          <!-- User Card -->
          <div class="bg-white rounded-xl shadow-lg p-6">
            <h2 class="text-xl font-bold text-gray-900 mb-4 flex items-center gap-2">
              <span>👤</span> User Information
            </h2>
            <div class="space-y-4">
              <div class="flex items-center gap-4">
                <div class="h-16 w-16 rounded-full bg-gradient-to-br from-blue-400 to-blue-600 flex items-center justify-center text-white font-bold text-2xl">
                  {{ props.paymentRequest.user.name.charAt(0).toUpperCase() }}
                </div>
                <div>
                  <p class="text-xl font-bold text-gray-900">{{ props.paymentRequest.user.name }}</p>
                  <p class="text-gray-600">{{ props.paymentRequest.user.email }}</p>
                </div>
              </div>
            </div>
          </div>

          <!-- Payment Details -->
          <div class="bg-white rounded-xl shadow-lg p-6">
            <h2 class="text-xl font-bold text-gray-900 mb-4 flex items-center gap-2">
              <span>💳</span> Payment Details
            </h2>
            <div class="space-y-4">
              <div class="grid grid-cols-2 gap-4">
                <div>
                  <label class="text-sm text-gray-600 font-semibold">From Number</label>
                  <p class="text-lg font-mono text-gray-900 mt-1">{{ props.paymentRequest.from_number }}</p>
                </div>
                <div>
                  <label class="text-sm text-gray-600 font-semibold">To Number</label>
                  <p class="text-lg font-mono text-gray-900 mt-1">{{ props.paymentRequest.to_number }}</p>
                </div>
              </div>
              <div>
                <label class="text-sm text-gray-600 font-semibold">Transaction ID</label>
                <p class="text-lg font-mono text-gray-900 mt-1 break-all">{{ props.paymentRequest.transaction_number }}</p>
              </div>
              <div class="grid grid-cols-2 gap-4">
                <div>
                  <label class="text-sm text-gray-600 font-semibold">Amount</label>
                  <p class="text-2xl font-bold text-green-600 mt-1">৳ {{ props.paymentRequest.amount }}</p>
                </div>
                <div>
                  <label class="text-sm text-gray-600 font-semibold">Requested On</label>
                  <p class="text-lg text-gray-900 mt-1">{{ formatDate(props.paymentRequest.created_at) }}</p>
                </div>
              </div>
            </div>
          </div>

          <!-- Approval Information (if approved) -->
          <div v-if="isApproved" class="bg-green-50 rounded-xl border-2 border-green-200 p-6">
            <h2 class="text-xl font-bold text-green-900 mb-4 flex items-center gap-2">
              <span>✅</span> Approval Information
            </h2>
            <div class="space-y-3">
              <div v-if="props.paymentRequest.approved_by">
                <label class="text-sm text-green-700 font-semibold">Approved By</label>
                <p class="text-lg text-green-900 mt-1">{{ props.paymentRequest.approved_by.name }}</p>
              </div>
              <div v-if="props.paymentRequest.approved_at">
                <label class="text-sm text-green-700 font-semibold">Approved On</label>
                <p class="text-lg text-green-900 mt-1">{{ formatDate(props.paymentRequest.approved_at) }}</p>
              </div>
              <div v-if="props.paymentRequest.admin_notes">
                <label class="text-sm text-green-700 font-semibold">Admin Notes</label>
                <p class="text-lg text-green-900 mt-1 bg-white rounded p-3">{{ props.paymentRequest.admin_notes }}</p>
              </div>
            </div>
          </div>

          <!-- Rejection Information (if rejected) -->
          <div v-if="isRejected" class="bg-red-50 rounded-xl border-2 border-red-200 p-6">
            <h2 class="text-xl font-bold text-red-900 mb-4 flex items-center gap-2">
              <span>❌</span> Rejection Information
            </h2>
            <div>
              <label class="text-sm text-red-700 font-semibold">Rejection Reason</label>
              <p class="text-lg text-red-900 mt-1 bg-white rounded p-3">{{ props.paymentRequest.rejection_reason }}</p>
            </div>
          </div>
        </div>

        <!-- Actions Sidebar -->
        <div class="lg:col-span-1">
          <div v-if="isPending" class="bg-white rounded-xl shadow-lg p-6 space-y-4">
            <h2 class="text-lg font-bold text-gray-900">Actions</h2>

            <!-- Admin Notes -->
            <div>
              <label class="block text-sm font-semibold text-gray-700 mb-2">Admin Notes (Optional)</label>
              <textarea
                v-model="form.admin_notes"
                placeholder="Add internal notes about this request..."
                class="w-full px-4 py-2 border-2 border-gray-200 rounded-lg focus:border-blue-500 focus:outline-none transition-colors text-sm"
                rows="4"
              ></textarea>
            </div>

            <!-- Approve Button -->
            <button
              @click="approveRequest"
              class="w-full px-4 py-3 bg-gradient-to-r from-green-600 to-green-700 text-white rounded-lg hover:from-green-700 hover:to-green-800 transition-all font-bold shadow-lg flex items-center justify-center gap-2"
            >
              <span>✅</span>
              <span>Approve & Add to Wallet</span>
            </button>

            <!-- Reject Button -->
            <button
              @click="rejectRequest"
              class="w-full px-4 py-3 bg-gradient-to-r from-red-600 to-red-700 text-white rounded-lg hover:from-red-700 hover:to-red-800 transition-all font-bold shadow-lg flex items-center justify-center gap-2"
            >
              <span>❌</span>
              <span>Reject Request</span>
            </button>
          </div>

          <!-- Info Box -->
          <div class="bg-blue-50 rounded-xl border-2 border-blue-200 p-6">
            <h3 class="font-bold text-blue-900 mb-3 flex items-center gap-2">
              <span>ℹ️</span> Important
            </h3>
            <ul class="text-sm text-blue-900 space-y-2">
              <li>✓ Verify transaction details before approval</li>
              <li>✓ Check payment method numbers match</li>
              <li>✓ Confirm transaction ID with payment provider</li>
              <li>✓ Once approved, amount is added to wallet</li>
            </ul>
          </div>
        </div>
      </div>
    </div>
  </AdminLayout>
</template>
