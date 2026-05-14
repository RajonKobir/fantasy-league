<script setup>
import { ref } from 'vue'
import { Head, Link } from '@inertiajs/vue3'
import AuthenticatedLayout from '@/Layouts/AuthenticatedLayout.vue'
import { useForm } from '@inertiajs/vue3'

const props = defineProps({ teams: Array, players: Array })
const form = useForm({
    team_id: '',
    player_id: '',
    captain: false,
    vice_captain: false
})

const submit = () => form.post('/admin/player-selections')
</script>

<template>
    <Head title="Add Player Selection" />
    <AuthenticatedLayout>
        <template #header>
            <div class="flex justify-between items-center">
                <h2 class="text-xl font-semibold text-gray-800">Add Player Selection</h2>
                <Link href="/admin/player-selections" class="btn-secondary">Back</Link>
            </div>
        </template>

        <div class="py-6 max-w-lg mx-auto">
            <div class="bg-white shadow-sm sm:rounded-lg p-6">
                <form @submit.prevent="submit" class="space-y-4">
                    <div>
                        <label class="block text-sm font-medium text-gray-700">Team</label>
                        <select v-model="form.team_id" class="input">
                            <option value="">Select Team</option>
                            <option v-for="team in props.teams" :key="team.id" :value="team.id">{{ team.name }}</option>
                        </select>
                        <span class="text-red-500 text-sm" v-if="form.errors.team_id">{{ form.errors.team_id }}</span>
                    </div>

                    <div>
                        <label class="block text-sm font-medium text-gray-700">Player</label>
                        <select v-model="form.player_id" class="input">
                            <option value="">Select Player</option>
                            <option v-for="player in props.players" :key="player.id" :value="player.id">{{ player.name }}</option>
                        </select>
                        <span class="text-red-500 text-sm" v-if="form.errors.player_id">{{ form.errors.player_id }}</span>
                    </div>

                    <div class="flex items-center space-x-4">
                        <label class="flex items-center space-x-2">
                            <input type="checkbox" v-model="form.captain" />
                            <span>Captain</span>
                        </label>
                        <label class="flex items-center space-x-2">
                            <input type="checkbox" v-model="form.vice_captain" />
                            <span>Vice-Captain</span>
                        </label>
                    </div>

                    <button type="submit" class="btn-primary" :disabled="form.processing">Save</button>
                </form>
            </div>
        </div>
    </AuthenticatedLayout>
</template>
