<script setup>
import { Head, Link, useForm } from '@inertiajs/vue3'
import { ref, computed } from 'vue'
import AdminLayout from '@/Layouts/AdminLayout.vue'
import SearchableSelect from '@/Components/SearchableSelect.vue'

// Helper: convert backend datetime to HTML datetime-local (YYYY-MM-DDTHH:MM)
function formatDateTime(dateStr) {
  if (!dateStr) return ''
  return String(dateStr).replace(' ', 'T').substring(0, 16)
}

// Convert datetime-local back to server-friendly format (YYYY-MM-DD HH:MM:SS)
function formatForServer(value) {
  if (!value) return ''
  let s = String(value)
  s = s.replace('T', ' ')
  // add seconds if missing
  if (s.length === 16) s = s + ':00'
  return s
}

defineOptions({
  layout: AdminLayout,
})

const props = defineProps({
  teams: Array,
  tournaments: Array,
  cities: Array,
})

const form = useForm({
  team_a_id: '',
  team_b_id: '',
  tournament_id: '',
  start_time: '',
  status: 'upcoming',
  venue_id: '',
})

const teamOptions = computed(() => props.teams || [])
const tournamentOptions = computed(() => props.tournaments || [])
const cityOptions = computed(() => props.cities || [])

function submit() {
  const prev = form.start_time
  form.start_time = formatForServer(form.start_time)

  form.post(route('admin.game-matches.store'), {
    onSuccess: () => {
      // Success handled by redirect
    },
    onError: () => {
      form.start_time = prev
    }
  })
}
</script>

<template>
  <Head title="Create Game Match" />

  <div>
    <div class="flex justify-between items-center mb-6">
      <h1 class="text-2xl font-bold">Create Game Match</h1>
      <Link
        href="/admin/game-matches"
        class="px-4 py-2 bg-gray-700 text-white rounded-lg hover:bg-gray-900"
      >
        ⬅ Back
      </Link>
    </div>

    <form @submit.prevent="submit" class="space-y-4 max-w-full sm:max-w-md">
      <div>
        <label class="block text-sm font-medium mb-1">Team A *</label>
        <SearchableSelect
          v-model="form.team_a_id"
          :options="teamOptions"
          placeholder="Select Team A"
          name="team_a_id"
          :isError="form.errors.team_a_id ? true : false"
        />
        <p v-if="form.errors.team_a_id" class="text-red-600 text-sm mt-1">{{ form.errors.team_a_id }}</p>
      </div>

      <div>
        <label class="block text-sm font-medium mb-1">Team B *</label>
        <SearchableSelect
          v-model="form.team_b_id"
          :options="teamOptions"
          placeholder="Select Team B"
          name="team_b_id"
          :isError="form.errors.team_b_id ? true : false"
        />
        <p v-if="form.errors.team_b_id" class="text-red-600 text-sm mt-1">{{ form.errors.team_b_id }}</p>
      </div>

      <div>
        <label class="block text-sm font-medium mb-1">Tournament (Optional)</label>
        <SearchableSelect
          v-model="form.tournament_id"
          :options="tournamentOptions"
          placeholder="Select Tournament"
          name="tournament_id"
          :isError="form.errors.tournament_id ? true : false"
        />
        <p v-if="form.errors.tournament_id" class="text-red-600 text-sm mt-1">{{ form.errors.tournament_id }}</p>
      </div>

      <div>
        <label class="block text-sm font-medium mb-1">Start Time *</label>
        <input
          v-model="form.start_time"
          type="datetime-local"
          class="w-full border rounded px-3 py-2"
          :class="{ 'border-red-500': form.errors.start_time }"
        />
        <p v-if="form.errors.start_time" class="text-red-600 text-sm mt-1">{{ form.errors.start_time }}</p>
      </div>

      <div>
        <label class="block text-sm font-medium mb-1">Venue (Optional)</label>
        <SearchableSelect
          v-model="form.venue_id"
          :options="cityOptions"
          placeholder="Select Venue"
          name="venue_id"
          :isError="form.errors.venue_id ? true : false"
        />
        <p v-if="form.errors.venue_id" class="text-red-600 text-sm mt-1">{{ form.errors.venue_id }}</p>
      </div>

      <div>
        <label class="block text-sm font-medium mb-1">Status</label>
        <select v-model="form.status" class="w-full border rounded px-3 py-2">
          <option value="upcoming">Upcoming</option>
          <option value="live">Live</option>
          <option value="completed">Completed</option>
        </select>
        <p v-if="form.errors.status" class="text-red-600 text-sm mt-1">{{ form.errors.status }}</p>
      </div>

      <div class="flex gap-2 pt-4">
        <button
          type="submit"
          class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
          :disabled="form.processing"
        >
          {{ form.processing ? 'Creating...' : 'Create Match' }}
        </button>
        <Link
          href="/admin/game-matches"
          class="px-4 py-2 bg-gray-600 text-white rounded-lg hover:bg-gray-700"
        >
          Cancel
        </Link>
      </div>
    </form>
  </div>
</template>
