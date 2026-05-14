<script setup>
import { Head, Link, useForm } from '@inertiajs/vue3'
import AdminLayout from '@/Layouts/AdminLayout.vue'
import SearchableSelect from '@/Components/SearchableSelect.vue'
import { computed } from 'vue'

defineOptions({
  layout: AdminLayout,
})

const props = defineProps({ tournaments: Array, players: Array, teams: Array, gameMatches: Array })

// Transform data for SearchableSelect component
const matchOptions = computed(() =>
  props.gameMatches.map(m => ({ id: m.id, label: `${m.team_a?.name || 'Team A'} vs ${m.team_b?.name || 'Team B'} (${m.start_time})` }))
)

const playerOptions = computed(() =>
  props.players.map(p => ({ id: p.id, label: `${p.name} (${p.team || 'N/A'})` }))
)

const teamOptions = computed(() =>
  props.teams.map(t => ({ id: t.id, label: t.name }))
)

// Use Inertia useForm so server validation and processing state are available
const form = useForm({ game_match_id: '', tournament_id: '', player_id: '', team_id: null, points: 0, note: '' })

function submit() {
  form.post(route('admin.points.store'))
}
</script>

<template>
  <Head title="Create Point" />

  <div class="flex justify-between items-center mb-6">
    <h1 class="text-2xl font-bold">Create Point</h1>
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
      <button @click.prevent="submit" :disabled="form.processing" :aria-disabled="form.processing" class="px-4 py-2 btn-primary">
        <span v-if="form.processing">Creating...</span>
        <span v-else>Create</span>
      </button>
    </div>
  </div>
</template>
