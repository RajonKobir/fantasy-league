<template>
  <AdminLayout>
    <div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <!-- Header -->
      <div class="mb-8 flex items-center justify-between">
        <div>
          <h1 class="text-3xl font-bold text-gray-900">Cancel Request Details</h1>
          <p class="text-gray-600 mt-2">#{{ cancelRequest.id }}</p>
        </div>
        <Link
          :href="route('admin.cancel-requests.index')"
          class="px-4 py-2 bg-gray-600 text-white rounded-lg hover:bg-gray-700 transition-colors"
        >
          ← Back
        </Link>
      </div>

      <!-- Success Message -->
      <div v-if="$page.props.flash?.success" class="mb-4 p-4 bg-green-50 border border-green-200 rounded-lg">
        <p class="text-green-800">✓ {{ $page.props.flash.success }}</p>
      </div>

      <!-- Error Messages -->
      <div v-if="$page.props.flash?.error" class="mb-4 p-4 bg-red-50 border border-red-200 rounded-lg">
        <p class="text-red-800">✗ {{ $page.props.flash.error }}</p>
      </div>

      <!-- Status Card -->
      <div class="bg-white rounded-lg shadow-sm p-6 mb-6">
        <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
          <!-- Status -->
          <div>
            <p class="text-sm text-gray-600">Status</p>
            <div class="mt-2">
              <span
                :class="{
                  'bg-yellow-100 text-yellow-800': cancelRequest.status === 'pending',
                  'bg-green-100 text-green-800': cancelRequest.status === 'approved',
                  'bg-red-100 text-red-800': cancelRequest.status === 'rejected',
                }"
                class="px-4 py-2 rounded-full font-semibold text-lg"
              >
                {{ cancelRequest.status.charAt(0).toUpperCase() + cancelRequest.status.slice(1) }}
              </span>
            </div>
          </div>

          <!-- Refund Percentage -->
          <div>
            <p class="text-sm text-gray-600">Refund Percentage</p>
            <p class="text-2xl font-bold text-gray-900 mt-2">
              {{ parseFloat(cancelRequest.refund_percentage_at_request || 0).toFixed(2) }}%
            </p>
          </div>

          <!-- Refund Amount -->
          <div>
            <p class="text-sm text-gray-600">Refund Amount</p>
            <p v-if="cancelRequest.refund_amount" class="text-2xl font-bold text-green-600 mt-2">
              {{ parseFloat(cancelRequest.refund_amount).toFixed(2) }}
            </p>
            <p v-else class="text-2xl font-bold text-gray-400 mt-2">-</p>
          </div>

          <!-- Requested Date -->
          <div>
            <p class="text-sm text-gray-600">Requested Date</p>
            <p class="text-sm font-medium text-gray-900 mt-2">
              {{ formatDate(cancelRequest.created_at) }}
            </p>
          </div>
        </div>
      </div>

      <!-- Request Details -->
      <div class="bg-white rounded-lg shadow-sm p-6 mb-6">
        <h2 class="text-xl font-bold text-gray-900 mb-4">Request Information</h2>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <!-- Fantasy Team Details -->
          <div class="border-r border-gray-200 pr-6">
            <h3 class="font-semibold text-gray-900 mb-3">Fantasy Team</h3>
            <div class="space-y-2 text-sm">
              <div>
                <span class="text-gray-600">Team Name:</span>
                <span class="font-medium text-gray-900">{{ cancelRequest.fantasy_team?.name }}</span>
              </div>
              <div>
                <span class="text-gray-600">Team ID:</span>
                <span class="font-medium text-gray-900">#{{ cancelRequest.fantasy_team?.id }}</span>
              </div>
              <div>
                <span class="text-gray-600">Team Status:</span>
                <span class="font-medium text-gray-900">{{ cancelRequest.fantasy_team?.status }}</span>
              </div>
              <div>
                <span class="text-gray-600">Created:</span>
                <span class="font-medium text-gray-900">{{ formatDate(cancelRequest.fantasy_team?.created_at) }}</span>
              </div>
            </div>
          </div>

          <!-- Tournament Details -->
          <div>
            <h3 class="font-semibold text-gray-900 mb-3">Tournament</h3>
            <div class="space-y-2 text-sm">
              <div>
                <span class="text-gray-600">Name:</span>
                <span class="font-medium text-gray-900">{{ cancelRequest.tournament?.name }}</span>
              </div>
              <div>
                <span class="text-gray-600">Entry Fee:</span>
                <span class="font-medium text-gray-900">{{ parseFloat(cancelRequest.tournament?.entry_fee || 0).toFixed(2) }}</span>
              </div>
              <div>
                <span class="text-gray-600">Refund %:</span>
                <span class="font-medium text-gray-900">{{ parseFloat(cancelRequest.tournament?.refund_percentage || 0).toFixed(2) }}%</span>
              </div>
              <div>
                <span class="text-gray-600">Status:</span>
                <span class="font-medium text-gray-900">{{ cancelRequest.tournament?.status }}</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- User Details -->
      <div class="bg-white rounded-lg shadow-sm p-6 mb-6">
        <h2 class="text-xl font-bold text-gray-900 mb-4">User Information</h2>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div>
            <span class="text-gray-600">Name:</span>
            <p class="font-medium text-gray-900">{{ cancelRequest.user?.name }}</p>
          </div>
          <div>
            <span class="text-gray-600">Email:</span>
            <p class="font-medium text-gray-900">{{ cancelRequest.user?.email }}</p>
          </div>
          <div>
            <span class="text-gray-600">Wallet Balance:</span>
            <p class="font-medium text-gray-900">{{ parseFloat(cancelRequest.user?.wallet_balance || 0).toFixed(2) }}</p>
          </div>
          <div>
            <span class="text-gray-600">User ID:</span>
            <p class="font-medium text-gray-900">#{{ cancelRequest.user?.id }}</p>
          </div>
        </div>
      </div>

      <!-- Admin Actions and Notes -->
      <div class="bg-white rounded-lg shadow-sm p-6 mb-6">
        <h2 class="text-xl font-bold text-gray-900 mb-4">Admin Decision</h2>

        <div class="space-y-4">
          <!-- Approved By -->
          <div v-if="cancelRequest.approved_by">
            <span class="text-gray-600">Approved By:</span>
            <p class="font-medium text-gray-900">{{ cancelRequest.approved_by_user?.name }}</p>
          </div>

          <!-- Approval Date -->
          <div v-if="cancelRequest.approved_at">
            <span class="text-gray-600">Decision Date:</span>
            <p class="font-medium text-gray-900">{{ formatDate(cancelRequest.approved_at) }}</p>
          </div>

          <!-- Admin Notes -->
          <div v-if="cancelRequest.admin_notes">
            <span class="text-gray-600 block mb-2">Admin Notes:</span>
            <p class="text-gray-900 bg-gray-50 p-3 rounded">{{ cancelRequest.admin_notes }}</p>
          </div>
        </div>
      </div>

      <!-- Action Buttons (only for pending requests) -->
      <div v-if="cancelRequest.status === 'pending'" class="bg-white rounded-lg shadow-sm p-6">
        <h2 class="text-xl font-bold text-gray-900 mb-4">Actions</h2>

        <div class="flex flex-col sm:flex-row gap-4">
          <!-- Approve Button -->
          <button
            @click="approvingRequest = true"
            class="flex-1 px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors font-semibold"
          >
            ✓ Approve & Issue Refund
          </button>

          <!-- Reject Button -->
          <button
            @click="rejectingRequest = true"
            class="flex-1 px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors font-semibold"
          >
            ✗ Reject Request
          </button>
        </div>
      </div>

      <!-- Approve Confirmation Modal -->
      <div v-if="approvingRequest" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
        <div class="bg-white rounded-lg p-6 max-w-md">
          <h3 class="text-lg font-bold text-gray-900 mb-4">Approve Cancel Request?</h3>
          <p class="text-gray-600 mb-4">
            This will issue a refund of <strong>{{ parseFloat(refundAmountCalculated).toFixed(2) }}</strong> to the user's wallet.
          </p>
          <div class="flex gap-3">
            <button
              @click="approvingRequest = false"
              class="flex-1 px-4 py-2 bg-gray-300 text-gray-900 rounded-lg hover:bg-gray-400 transition-colors"
            >
              Cancel
            </button>
            <button
              @click="approveRequest"
              :disabled="approveForm.processing"
              class="flex-1 px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors disabled:opacity-50"
            >
              {{ approveForm.processing ? 'Processing...' : 'Confirm' }}
            </button>
          </div>
        </div>
      </div>

      <!-- Reject Confirmation Modal -->
      <div v-if="rejectingRequest" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
        <div class="bg-white rounded-lg p-6 max-w-md">
          <h3 class="text-lg font-bold text-gray-900 mb-4">Reject Cancel Request?</h3>
          <p class="text-gray-600 mb-4">
            The user will be notified of the rejection.
          </p>
          <textarea
            v-model="rejectForm.admin_notes"
            placeholder="Reason for rejection (optional)"
            class="w-full px-3 py-2 border border-gray-300 rounded-lg mb-4 focus:ring-2 focus:ring-red-500 focus:border-transparent"
          />
          <div class="flex gap-3">
            <button
              @click="rejectingRequest = false"
              class="flex-1 px-4 py-2 bg-gray-300 text-gray-900 rounded-lg hover:bg-gray-400 transition-colors"
            >
              Cancel
            </button>
            <button
              @click="rejectRequest"
              :disabled="rejectForm.processing"
              class="flex-1 px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors disabled:opacity-50"
            >
              {{ rejectForm.processing ? 'Processing...' : 'Reject' }}
            </button>
          </div>
        </div>
      </div>
    </div>
  </AdminLayout>
</template>

<script setup>
import { ref, computed } from 'vue'
import { Link, useForm } from '@inertiajs/vue3'
import AdminLayout from '@/Layouts/AdminLayout.vue'
import { useDate } from '@/composables/useDate'

const props = defineProps({
  cancelRequest: Object,
})

const { formatDate } = useDate()

const approvingRequest = ref(false)
const rejectingRequest = ref(false)

const approveForm = useForm('post', route('admin.cancel-requests.approve', props.cancelRequest.id), {})
const rejectForm = useForm('post', route('admin.cancel-requests.reject', props.cancelRequest.id), {
  admin_notes: '',
})

const refundAmountCalculated = computed(() => {
  const entryFee = parseFloat(props.cancelRequest.tournament?.entry_fee || 0)
  const refundPercentage = parseFloat(props.cancelRequest.refund_percentage_at_request || 0)
  return entryFee * (refundPercentage / 100)
})

const approveRequest = () => {
  approveForm.post(route('admin.cancel-requests.approve', props.cancelRequest.id), {
    preserveScroll: true,
    onSuccess: () => {
      approvingRequest.value = false
    },
  })
}

const rejectRequest = () => {
  rejectForm.post(route('admin.cancel-requests.reject', props.cancelRequest.id), {
    preserveScroll: true,
    onSuccess: () => {
      rejectingRequest.value = false
    },
  })
}
</script>
