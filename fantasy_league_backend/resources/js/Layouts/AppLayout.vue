<script setup>
import { Link } from '@inertiajs/vue3'
import ApplicationLogo from '@/Components/ApplicationLogo.vue'
import { ref } from 'vue'

const mobileOpen = ref(false)
</script>

<template>
  <div class="flex flex-col min-h-screen bg-gray-50">

    <!-- Header -->
    <header class="bg-white shadow sticky top-0 z-20">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 flex justify-between items-center h-16">
        <!-- Logo -->
        <Link href="/" class="flex items-center space-x-2">
          <ApplicationLogo class="h-8 w-auto" />
          <span class="font-bold text-lg text-gray-800">My App</span>
        </Link>

        <!-- Desktop Nav -->
        <nav class="hidden md:flex space-x-6 text-gray-700 font-medium">
          <Link href="/" class="hover:text-gray-900">Home</Link>
          <Link href="/dashboard" class="hover:text-gray-900">Dashboard</Link>
          <Link href="/profile" class="hover:text-gray-900">Profile</Link>
        </nav>

        <!-- Mobile Menu Button -->
        <button class="md:hidden p-2 rounded hover:bg-gray-200" @click="mobileOpen = !mobileOpen">
          ☰
        </button>
      </div>

      <!-- Mobile Nav -->
      <div v-if="mobileOpen" class="md:hidden bg-gray-100 border-t px-4 py-3 space-y-2">
        <Link href="/" class="block">Home</Link>
        <Link href="/dashboard" class="block">Dashboard</Link>
        <Link href="/profile" class="block">Profile</Link>
      </div>
    </header>

    <!-- Main Content -->
    <main class="flex-1 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
      <slot />
    </main>

    <!-- Footer -->
    <footer class="bg-white border-t py-4 mt-6">
      <div class="max-w-7xl mx-auto px-4 text-center text-sm text-gray-500">
        © {{ new Date().getFullYear() }} My App. All rights reserved.
      </div>
    </footer>
  </div>
</template>
