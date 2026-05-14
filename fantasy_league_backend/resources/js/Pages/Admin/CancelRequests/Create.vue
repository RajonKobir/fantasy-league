<template>
  <AdminLayout>
    <div class="max-w-2xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <!-- Header -->
      <div class="mb-8 flex items-center justify-between">
        <div>
          <h1 class="text-3xl font-bold text-gray-900">Create Cancel Request</h1>
          <p class="text-gray-600 mt-2">Manually create a new cancel request for a fantasy team</p>
        </div>
        <Link
          :href="route('admin.cancel-requests.index')"
          class="px-4 py-2 bg-gray-600 text-white rounded-lg hover:bg-gray-700 transition-colors"
        >
          ← Back
        </Link>
      </div>

      <!-- Error Messages -->
      <div v-if="Object.keys(form.errors).length > 0" class="mb-4 p-4 bg-red-50 border border-red-200 rounded-lg">
        <p class="text-red-800 font-semibold mb-2">Validation errors:</p>
        <ul class="list-disc list-inside text-red-800 space-y-1">
          <li v-for="(error, field) in form.errors" :key="field">
            <strong>{{ field }}:</strong> {{ error }}
          </li>
        </ul>
      </div>

      <!-- Form -->
      <form @submit.prevent="submitForm" class="bg-white rounded-lg shadow-sm p-6">
        <!-- Select Fantasy Team with Search -->
        <div class="mb-6 relative">
          <label class="block text-sm font-semibold text-gray-700 mb-2">
            Select Fantasy Team
            <span class="text-red-600">*</span>
          </label>

          <!-- Search Input -->
          <input
            v-model="teamSearch"
            type="text"
            placeholder="Search team name, user, or tournament..."
            @focus="dropdownOpen = true"
            @blur="handleBlur"
            class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            :class="{ 'border-red-500': form.errors.fantasy_team_id }"
          />

          <!-- Dropdown Menu -->
          <div v-if="dropdownOpen && filteredTeams.length > 0" class="absolute top-full left-0 right-0 mt-1 bg-white border border-gray-300 rounded-lg shadow-lg z-10 max-h-60 overflow-y-auto">
            <div
              v-for="team in filteredTeams"
              :key="team.id"
              @click="selectTeam(team)"
              class="px-4 py-2 hover:bg-blue-50 cursor-pointer border-b border-gray-100 last:border-0"
            >
              <div class="font-medium text-gray-900">{{ team.name }}</div>
              <div class="text-xs text-gray-500">
                {{ team.tournament?.name }} • User: {{ team.user?.name }} • Entry: {{ formatCurrency(team.entry_fee) }}
              </div>
            </div>
          </div>

          <!-- Empty State -->
          <div v-if="dropdownOpen && filteredTeams.length === 0 && teamSearch" class="absolute top-full left-0 right-0 mt-1 bg-white border border-gray-300 rounded-lg shadow-lg z-10 px-4 py-3">
            <p class="text-gray-500 text-sm">No teams found matching your search.</p>
          </div>

          <!-- Selected Team Display -->
          <div v-if="selectedTeam" class="mt-2 p-2 bg-blue-50 border border-blue-200 rounded text-sm">
            <strong>Selected:</strong> {{ selectedTeam.name }} ({{ selectedTeam.tournament?.name }})
          </div>

          <p v-if="form.errors.fantasy_team_id" class="text-red-600 text-sm mt-1">
            {{ form.errors.fantasy_team_id }}
          </p>
        </div>

        <!-- Team Information Preview -->
        <div v-if="selectedTeam" class="mb-6 p-4 bg-blue-50 border border-blue-200 rounded-lg">
          <h3 class="font-semibold text-blue-900 mb-3">Team Information</h3>
          <div class="grid grid-cols-1 sm:grid-cols-2 gap-4 text-sm">
            <div>
              <span class="text-blue-700">Team Name:</span>
              <p class="font-medium text-blue-900">{{ selectedTeam.name }}</p>
            </div>
            <div>
              <span class="text-blue-700">User:</span>
              <p class="font-medium text-blue-900">{{ selectedTeam.user?.name }} ({{ selectedTeam.user?.email }})</p>
            </div>
            <div>
              <span class="text-blue-700">Tournament:</span>
              <p class="font-medium text-blue-900">{{ selectedTeam.tournament?.name }}</p>
            </div>
            <div>
              <span class="text-blue-700">Entry Fee:</span>
              <p class="font-medium text-blue-900">{{ formatCurrency(selectedTeam.entry_fee) }}</p>
            </div>
            <div>
              <span class="text-blue-700">Refund %:</span>
              <p class="font-medium text-blue-900">{{ formatCurrency(selectedTeam.tournament?.refund_percentage || 0) }}%</p>
            </div>
            <div>
              <span class="text-blue-700">Expected Refund:</span>
              <p class="font-medium text-green-600">
                {{ formatCurrency(parseFloat(selectedTeam.entry_fee || 0) * (parseFloat(selectedTeam.tournament?.refund_percentage || 0) / 100)) }}
              </p>
            </div>
          </div>
        </div>

        <!-- User Wallet Information -->
        <div v-if="selectedTeam" class="mb-6 p-4 bg-amber-50 border border-amber-200 rounded-lg">
          <h3 class="font-semibold text-amber-900 mb-2">User Wallet</h3>
          <p class="text-sm text-amber-800">
            <strong>Current Balance:</strong> {{ formatCurrency(selectedTeam.user?.wallet_balance || 0) }}
          </p>
          <p class="text-xs text-amber-700 mt-2">
            After approval: {{ formatCurrency(parseFloat(selectedTeam.user?.wallet_balance || 0) + calculatedRefund) }}
          </p>
        </div>

        <!-- Submit Button -->
        <div class="flex gap-3">
          <button
            type="button"
            @click="goBack"
            class="px-6 py-2 bg-gray-300 text-gray-900 rounded-lg hover:bg-gray-400 transition-colors font-semibold"
          >
            Cancel
          </button>
          <button
            type="submit"
            :disabled="form.processing || !form.fantasy_team_id"
            class="flex-1 px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors font-semibold disabled:opacity-50"
          >
            {{ form.processing ? 'Creating...' : 'Create Cancel Request' }}
          </button>
        </div>
      </form>

      <!-- Info Box -->
      <div class="mt-6 p-4 bg-blue-50 border border-blue-200 rounded-lg">
        <p class="text-sm text-blue-800">
          <strong>Note:</strong> Creating a cancel request will mark it as pending. An admin must approve it before the refund is issued to the user's wallet.
        </p>
      </div>
    </div>
  </AdminLayout>
</template>

<script setup>
import { ref, computed } from 'vue'
import { Link, useForm } from '@inertiajs/vue3'
import AdminLayout from '@/Layouts/AdminLayout.vue'

const props = defineProps({
  fantasyTeams: Array,
})

const form = useForm('post', route('admin.cancel-requests.store'), {
  fantasy_team_id: '',
})

const teamSearch = ref('')
const dropdownOpen = ref(false)

const filteredTeams = computed(() => {
  if (!props.fantasyTeams) return []
  if (!teamSearch.value) return props.fantasyTeams

  const search = teamSearch.value.toLowerCase()
  return props.fantasyTeams.filter(team =>
    team.name?.toLowerCase().includes(search) ||
    team.user?.name?.toLowerCase().includes(search) ||
    team.user?.email?.toLowerCase().includes(search) ||
    team.tournament?.name?.toLowerCase().includes(search)
  )
})

const selectedTeam = computed(() => {
  if (!form.fantasy_team_id) return null
  return props.fantasyTeams.find(team => team.id === parseInt(form.fantasy_team_id))
})

const calculatedRefund = computed(() => {
  if (!selectedTeam.value) return 0
  const entryFee = parseFloat(selectedTeam.value.entry_fee || 0)
  const refundPercentage = parseFloat(selectedTeam.value.tournament?.refund_percentage || 0)
  return entryFee * (refundPercentage / 100)
})

const formatCurrency = (value) => {
  return parseFloat(value || 0).toFixed(2)
}

const selectTeam = (team) => {
  form.fantasy_team_id = team.id
  teamSearch.value = ''
  dropdownOpen.value = false
}

const handleBlur = () => {
  setTimeout(() => {
    dropdownOpen.value = false
  }, 200)
}

const submitForm = () => {
  form.post(route('admin.cancel-requests.store'))
}

const goBack = () => {
  window.location.href = route('admin.cancel-requests.index')
}
</script>
