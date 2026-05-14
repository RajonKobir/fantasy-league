<script setup>
import { Head } from '@inertiajs/vue3'
import AdminLayout from '@/Layouts/AdminLayout.vue'
import StatCard from '@/Components/StatCard.vue'
import { useDate } from '@/composables/useDate'

const { formatDate } = useDate()

defineOptions({
  layout: AdminLayout,
})

defineProps({
  stats: Object,
  matches: Array,
})
</script>

<template>
  <Head title="Admin Dashboard" />

  <div class="space-y-8">
    <!-- Page title -->
    <div>
      <h1 class="text-4xl font-bold text-gray-900">Dashboard</h1>
      <p class="text-gray-600 mt-2">Welcome to your Fantasy League admin panel</p>
    </div>

    <!-- Stats Cards -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
      <StatCard label="Total Players" :value="stats.players" icon="🏏" color="blue" />
      <StatCard label="Upcoming Matches" :value="stats.matches" icon="🔥" color="orange" />
      <StatCard label="Active Teams" :value="stats.teams" icon="🎯" color="green" />
      <StatCard label="Tournaments" :value="stats.tournaments || 0" icon="🏆" color="purple" />
    </div>

    <!-- Upcoming Matches -->
    <div class="bg-white rounded-xl shadow-lg hover:shadow-xl transition-shadow overflow-hidden">
      <div class="px-6 py-4 bg-gradient-to-r from-blue-600 to-blue-700 text-white">
        <h2 class="text-2xl font-bold flex items-center gap-2">
          <span>🔥</span>
          <span>Upcoming Matches</span>
        </h2>
      </div>

      <div class="overflow-x-auto">
        <table class="w-full">
          <thead>
            <tr class="border-b bg-gray-50 text-gray-700 text-sm font-semibold uppercase tracking-wider">
              <th class="px-6 py-4 text-left">ID</th>
              <th class="px-6 py-4 text-left">Team A</th>
              <th class="px-6 py-4 text-left">Team B</th>
              <th class="px-6 py-4 text-left">Start Time</th>
              <th class="px-6 py-4 text-left">Status</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-200">
            <tr v-for="match in matches" :key="match.id" class="hover:bg-gray-50 transition-colors">
              <td class="px-6 py-4 text-sm font-medium text-gray-900">#{{ match.id }}</td>
              <td class="px-6 py-4 text-sm text-gray-600">{{ match.team_a }}</td>
              <td class="px-6 py-4 text-sm text-gray-600">{{ match.team_b }}</td>
              <td class="px-6 py-4 text-sm text-gray-600">
                {{ formatDate(match.start_time) }}
              </td>
              <td class="px-6 py-4 text-sm">
                <span
                  :class="{
                    'bg-blue-100 text-blue-800': match.status === 'upcoming',
                    'bg-green-100 text-green-800': match.status === 'live',
                    'bg-gray-100 text-gray-800': match.status === 'completed'
                  }"
                  class="badge"
                >
                  {{ match.status }}
                </span>
              </td>
            </tr>
            <tr v-if="matches.length === 0">
              <td colspan="5" class="px-6 py-8 text-center text-gray-500">
                <div class="flex flex-col items-center gap-2">
                  <span class="text-3xl">📭</span>
                  <span>No upcoming matches</span>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>
