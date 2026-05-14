<script setup>
import { Head } from '@inertiajs/vue3'
import AuthenticatedLayout from '@/Layouts/AuthenticatedLayout.vue'

defineOptions({
  layout: AuthenticatedLayout,
})

defineProps({
  stats: Object,
  matches: Array,
})
</script>

<template>
  <Head title="Admin Dashboard" />

  <div class="space-y-6">
    <h1 class="text-2xl font-bold">Dashboard</h1>

    <!-- Stats -->
    <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
      <div class="bg-white shadow rounded-lg p-4 sm:p-6 flex flex-col items-center">
        <span class="text-gray-500 text-sm">Players</span>
        <span class="text-2xl sm:text-3xl font-bold">{{ stats.players }}</span>
      </div>
      <div class="bg-white shadow rounded-lg p-4 sm:p-6 flex flex-col items-center">
        <span class="text-gray-500 text-sm">Matches</span>
        <span class="text-2xl sm:text-3xl font-bold">{{ stats.matches }}</span>
      </div>
      <div class="bg-white shadow rounded-lg p-4 sm:p-6 flex flex-col items-center">
        <span class="text-gray-500 text-sm">Teams</span>
        <span class="text-2xl sm:text-3xl font-bold">{{ stats.teams }}</span>
      </div>
    </div>

    <!-- Matches -->
    <div class="bg-white shadow rounded-lg p-4 sm:p-6">
      <h2 class="text-xl font-semibold mb-4">Upcoming Matches</h2>

      <!-- Mobile: stacked list -->
      <div class="sm:hidden space-y-3">
        <div v-for="match in matches" :key="match.id" class="p-3 bg-gray-50 rounded-lg border">
          <div class="flex items-center justify-between">
            <div class="text-sm text-gray-600">Match #{{ match.id }}</div>
            <div class="text-xs text-blue-600 uppercase font-medium">{{ match.status }}</div>
          </div>
          <div class="mt-2 text-sm">
            <div class="font-medium truncate">{{ match.team_a }} vs {{ match.team_b }}</div>
            <div class="text-gray-500 text-xs mt-1">{{ new Date(match.start_time).toLocaleString() }}</div>
          </div>
        </div>
        <div v-if="matches.length === 0" class="text-center text-gray-500 py-6">No upcoming matches.</div>
      </div>

      <!-- Desktop/tablet: regular table -->
      <div class="hidden sm:block overflow-x-auto -mx-4 px-4">
        <table class="min-w-full border border-gray-200">
          <thead class="bg-gray-100 text-gray-700 uppercase text-sm">
            <tr>
              <th class="px-4 py-2 text-left">Match ID</th>
              <th class="px-4 py-2 text-left">Team A</th>
              <th class="px-4 py-2 text-left">Team B</th>
              <th class="px-4 py-2 text-left">Start Time</th>
              <th class="px-4 py-2 text-left">Status</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="match in matches" :key="match.id" class="border-t hover:bg-gray-50">
              <td class="px-4 py-2">{{ match.id }}</td>
              <td class="px-4 py-2">{{ match.team_a }}</td>
              <td class="px-4 py-2">{{ match.team_b }}</td>
              <td class="px-4 py-2">{{ new Date(match.start_time).toLocaleString() }}</td>
              <td class="px-4 py-2 capitalize">{{ match.status }}</td>
            </tr>
            <tr v-if="matches.length === 0">
              <td colspan="5" class="px-4 py-6 text-center text-gray-500">No upcoming matches.</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>
