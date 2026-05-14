

<template>
  <Head :title="`Manage Points - ${match.team_a} vs ${match.team_b}`" />
  <div class="max-w-4xl mx-auto py-6">
    <h1 class="text-2xl font-bold mb-4">Manage Points: {{ match.team_a }} vs {{ match.team_b }}</h1>

    <form @submit.prevent="submit" class="space-y-4">
      <table class="w-full table-auto border">
        <thead>
          <tr class="bg-gray-100">
            <th class="px-2 py-1">Player</th>
            <th class="px-2 py-1">Points</th>
            <th class="px-2 py-1">Note</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="(row, idx) in form.points" :key="row.player_id" class="border-t">
            <td class="px-2 py-1">{{ row.player_name }}</td>
            <td class="px-2 py-1">
              <input v-model.number="row.points" type="number" min="0" max="1000" class="border rounded px-2 py-1 w-20" />
            </td>
            <td class="px-2 py-1">
              <input v-model="row.note" type="text" class="border rounded px-2 py-1 w-full" placeholder="Optional note" />
            </td>
          </tr>
        </tbody>
      </table>
      <button type="submit" class="btn-primary px-4 py-2">Save Points</button>
      <span v-if="showSuccess" class="ml-4 text-green-600">Points updated!</span>
    </form>

    <div class="mt-8">
      <button @click="triggerCronJob" :disabled="isRunningCron" class="btn-secondary px-4 py-2">
        Update Fantasy Team Points (Cron)
      </button>
      <span v-if="showCronSuccess" class="ml-4 text-green-600">Fantasy team points updated!</span>
      <span v-if="showCronError" class="ml-4 text-red-600">{{ cronErrorMessage }}</span>
    </div>
  </div>
</template>
<script setup>
import { Head, useForm } from '@inertiajs/vue3'
import AdminLayout from '@/Layouts/AdminLayout.vue'
import { ref } from 'vue'
import axios from 'axios'

defineOptions({
  layout: AdminLayout,
})

const props = defineProps({
  match: {
    type: Object,
    required: true,
  },
  teamAPlayers: {
    type: Array,
    required: true,
  },
  teamBPlayers: {
    type: Array,
    required: true,
  },
  matchPoints: {
    type: Object,
    required: true,
  },
})

const form = useForm({
  points: [],
})

const showSuccess = ref(false)
const showCronSuccess = ref(false)
const showCronError = ref(false)
const cronErrorMessage = ref('')
const isRunningCron = ref(false)

// Initialize form with existing points
const initializeForm = () => {
  const allPlayers = [...props.teamAPlayers, ...props.teamBPlayers]
  form.points = allPlayers.map(player => {
    const existingPoint = props.matchPoints[player.id]
    return {
      player_id: player.id,
      player_name: player.name,
      points: existingPoint?.points || 0,
      note: existingPoint?.note || '',
    }
  })
}

initializeForm()

const submit = () => {
  form.post(route('admin.game-matches.points.update', props.match.id), {
    preserveScroll: true,
    onSuccess: () => {
      showSuccess.value = true
      setTimeout(() => {
        showSuccess.value = false
      }, 3000)
    },
  })
}

const triggerCronJob = () => {
  // Open the streaming progress page in a new tab, which will connect to the server-sent events stream
  const tournamentId = props.match.tournament_id ? `?tournament_id=${encodeURIComponent(props.match.tournament_id)}` : ''
  const url = `/admin/cron/update-fantasy-team-points${tournamentId}`
  window.open(url, '_blank')
}</script>

