<script setup>
import { Head, Link, useForm } from '@inertiajs/vue3'
import { computed } from 'vue'
import AdminLayout from '@/Layouts/AdminLayout.vue'
import SearchableSelect from '@/Components/SearchableSelect.vue'

defineOptions({
  layout: AdminLayout,
})

const { point, tournaments, players, teams, gameMatches } = defineProps({ point: Object, tournaments: Array, players: Array, teams: Array, gameMatches: Array })

// Transform data for SearchableSelect component
const matchOptions = computed(() =>
  gameMatches.map(m => ({ id: m.id, label: `${m.team_a?.name || 'Team A'} vs ${m.team_b?.name || 'Team B'} (${m.start_time})` }))
)

const tournamentOptions = computed(() =>
  tournaments.map(t => ({ id: t.id, label: t.name }))
)

const playerOptions = computed(() =>
  players.map(p => ({ id: p.id, label: `${p.name} (${p.team || 'N/A'})` }))
)

const teamOptions = computed(() =>
  teams.map(t => ({ id: t.id, label: t.name }))
)

// Use Inertia's useForm so we get processing state and server-side validation errors
// Convert IDs to numbers for proper comparison and SearchableSelect binding
const form = useForm({
  game_match_id: Number(point.game_match_id),
  tournament_id: Number(point.tournament_id),
  player_id: Number(point.player_id),
  points: point.points,
  note: point.note || '',
  team_id: point.team_id ? Number(point.team_id) : null
})

// Track original values for change detection (as numbers)
const originalTournamentId = Number(point.tournament_id)
const originalPlayerId = Number(point.player_id)
const originalPoints = point.points
const originalNote = point.note || ''
const originalTeamId = point.team_id ? Number(point.team_id) : null

const hasChanges = computed(() => {
  return form.tournament_id !== originalTournamentId ||
         form.player_id !== originalPlayerId ||
         form.points !== originalPoints ||
         form.note !== originalNote ||
         form.team_id !== originalTeamId
})

function submit() {
  form.put(route('admin.points.update', point.id))
}
</script>

<template>
  <Head :title="`Edit Point #${point.id}`" />

  <div class="flex justify-between items-center mb-6">
    <h1 class="text-2xl font-bold">Edit Point</h1>
    <Link href="/admin/points" class="px-3 py-2 bg-gray-200 rounded">Back</Link>
  </div>

  <div class="space-y-4 max-w-2xl">
    <div>
      <label class="block text-sm font-medium mb-1">Game Match *</label>
      <SearchableSelect
        v-model="form.game_match_id"
        :options="matchOptions"
        placeholder="Search match..."
        name="game_match_id"
        :is-error="!!form.errors.game_match_id"
      />
      <div v-if="form.errors.game_match_id" class="text-red-600 text-sm mt-1">{{ form.errors.game_match_id }}</div>
    </div>

    <div>
      <label class="block text-sm font-medium mb-1">Player *</label>
      <SearchableSelect
        v-model="form.player_id"
        :options="playerOptions"
        placeholder="Search player..."
        name="player_id"
        :is-error="!!form.errors.player_id"
      />
      <div v-if="form.errors.player_id" class="text-red-600 text-sm mt-1">{{ form.errors.player_id }}</div>
    </div>

    <div>
      <label class="block text-sm font-medium mb-1">Team (optional)</label>
      <SearchableSelect
        v-model="form.team_id"
        :options="teamOptions"
        placeholder="Search team..."
        name="team_id"
        :is-error="!!form.errors.team_id"
      />
      <div v-if="form.errors.team_id" class="text-red-600 text-sm mt-1">{{ form.errors.team_id }}</div>
    </div>

    <div>
      <label class="block text-sm font-medium">Points</label>
      <input type="number" v-model.number="form.points" class="mt-1 w-full border rounded p-2" />
      <div v-if="form.errors.points" class="text-red-600 text-sm mt-1">{{ form.errors.points }}</div>
    </div>

    <div>
      <label class="block text-sm font-medium">Note</label>
      <input v-model="form.note" class="mt-1 w-full border rounded p-2" />
      <div v-if="form.errors.note" class="text-red-600 text-sm mt-1">{{ form.errors.note }}</div>
    </div>

    <div>
      <button @click.prevent="submit" :disabled="!hasChanges || form.processing" :aria-disabled="!hasChanges || form.processing" class="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 disabled:bg-gray-400 disabled:cursor-not-allowed">
        <span v-if="form.processing">Saving...</span>
        <span v-else>Save</span>
      </button>
    </div>
  </div>
</template>
