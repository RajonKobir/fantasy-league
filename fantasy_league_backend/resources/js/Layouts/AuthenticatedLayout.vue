<script setup>
import { ref, onMounted, watch, onUnmounted } from 'vue'
import ApplicationLogo from '@/Components/ApplicationLogo.vue'
import Dropdown from '@/Components/Dropdown.vue'
import DropdownLink from '@/Components/DropdownLink.vue'
import NavLink from '@/Components/NavLink.vue'
import ResponsiveNavLink from '@/Components/ResponsiveNavLink.vue'
import { Link, usePage } from '@inertiajs/vue3'

const showingNavigationDropdown = ref(false)
const mobileOpen = ref(false)
const page = usePage()

// Close mobile drawer on Escape
const _onKeydownAuth = (e) => {
  if (e.key === 'Escape' && mobileOpen.value) {
    mobileOpen.value = false
  }
}

watch(mobileOpen, (val) => {
  if (val) document.addEventListener('keydown', _onKeydownAuth)
  else document.removeEventListener('keydown', _onKeydownAuth)
})

onUnmounted(() => document.removeEventListener('keydown', _onKeydownAuth))
// Reactive flash messages
const flashSuccess = ref(page.props.flash?.success || null)
const flashError = ref(page.props.flash?.error || null)

// Dismiss function
const dismissFlash = (type) => {
  if (type === 'success') flashSuccess.value = null
  if (type === 'error') flashError.value = null
}

// Auto-dismiss after 5 seconds
onMounted(() => {
  if (flashSuccess.value) setTimeout(() => dismissFlash('success'), 5000)
  if (flashError.value) setTimeout(() => dismissFlash('error'), 5000)
})
</script>

<template>
  <div>
    <div class="min-h-screen bg-gray-100">
      <!-- Navbar -->
      <nav class="border-b border-gray-100 bg-white">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div class="flex justify-between h-16 items-center">
            <div class="flex items-center space-x-4">
              <Link href="/" class="flex items-center gap-2">
                <ApplicationLogo class="h-8 w-auto" />
                <span class="font-bold text-lg text-gray-800">Admin</span>
              </Link>
            </div>

            <!-- Desktop nav -->
            <div class="hidden md:flex items-center space-x-6">
              <NavLink href="/dashboard" class="">Dashboard</NavLink>
              <NavLink href="/admin/players">Players</NavLink>
              <NavLink href="/admin/teams">Teams</NavLink>
              <NavLink href="/admin/tournaments">Tournaments</NavLink>

              <!-- Profile dropdown -->
              <Dropdown>
                <template #trigger>
                  <button class="px-3 py-2 rounded hover:bg-gray-100">{{ page.props.auth.user.name }}</button>
                </template>
                <template #content>
                  <DropdownLink href="/profile">Profile</DropdownLink>
                  <form method="POST" action="/logout">
                    <button type="submit" class="w-full text-left text-red-600 px-3 py-2">Logout</button>
                  </form>
                </template>
              </Dropdown>
            </div>

            <!-- Mobile menu button -->
            <div class="md:hidden">
              <button
                @click="mobileOpen = !mobileOpen"
                :aria-expanded="mobileOpen"
                aria-controls="mobile-nav"
                aria-label="Toggle navigation"
                class="p-2 w-9 h-9 rounded-md bg-transparent hover:bg-gray-200 flex items-center justify-center focus:outline-none focus:ring-2 focus:ring-gray-300"
              >
                <span v-if="!mobileOpen" aria-hidden>☰</span>
                <span v-else aria-hidden>✕</span>
              </button>
            </div>
          </div>

          <!-- Mobile nav (off-canvas drawer) -->
          <transition name="slide">
            <div v-if="mobileOpen" class="md:hidden fixed inset-0 z-40 flex">
              <div class="fixed inset-0 bg-black bg-opacity-40" @click="mobileOpen = false" aria-hidden="true"></div>

              <nav id="mobile-nav" class="relative bg-white w-64 h-full shadow-lg p-4 overflow-y-auto" role="navigation" aria-label="Mobile navigation">
                <div class="flex items-center justify-between mb-4">
                  <Link href="/" class="flex items-center gap-2 font-bold">
                    <ApplicationLogo class="h-6 w-auto" />
                    <span>Admin</span>
                  </Link>
                  <button @click="mobileOpen = false" aria-label="Close navigation" class="p-2 rounded hover:bg-gray-100">✕</button>
                </div>

                <ResponsiveNavLink href="/dashboard" @click="mobileOpen = false">Dashboard</ResponsiveNavLink>
                <ResponsiveNavLink href="/admin/players" @click="mobileOpen = false">Players</ResponsiveNavLink>
                <ResponsiveNavLink href="/admin/teams" @click="mobileOpen = false">Teams</ResponsiveNavLink>
                <ResponsiveNavLink href="/admin/tournaments" @click="mobileOpen = false">Tournaments</ResponsiveNavLink>

                <div class="border-t pt-2 mt-4">
                  <Link href="/profile" class="block px-4 py-2" @click="mobileOpen = false">Profile</Link>
                  <form method="post" action="/logout" class="mt-2">
                    <button type="submit" class="w-full text-left text-red-600 px-4 py-2">Logout</button>
                  </form>
                </div>
              </nav>
            </div>
          </transition>
        </div>
      </nav>

      <!-- Page Heading -->
      <header v-if="$slots.header" class="bg-white shadow">
        <div class="mx-auto max-w-7xl px-4 py-6 sm:px-6 lg:px-8">
          <slot name="header" />
        </div>
      </header>

      <!-- Flash Messages with Transition + Close Button -->
      <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 mt-4 space-y-2">
        <Transition name="fade">
          <div
            v-if="flashSuccess"
            class="relative bg-green-100 border border-green-400 text-green-700 px-4 py-3 rounded"
          >
            {{ flashSuccess }}
            <button
              @click="dismissFlash('success')"
              class="absolute top-1 right-2 text-green-700 hover:text-green-900 font-bold"
            >
              &times;
            </button>
          </div>
        </Transition>

        <Transition name="fade">
          <div
            v-if="flashError"
            class="relative bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded"
          >
            {{ flashError }}
            <button
              @click="dismissFlash('error')"
              class="absolute top-1 right-2 text-red-700 hover:text-red-900 font-bold"
            >
              &times;
            </button>
          </div>
        </Transition>
      </div>

      <!-- Page Content -->
      <main>
        <div class="w-full max-w-full lg:max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
          <slot />
        </div>
      </main>
    </div>
  </div>
</template>

<style>
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.5s;
}
.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}

/* Slide transition for mobile drawer */
.slide-enter-active, .slide-leave-active {
  transition: transform 0.18s ease-out;
}
.slide-enter-from, .slide-leave-to {
  transform: translateX(-100%);
}
.slide-enter-to, .slide-leave-from {
  transform: translateX(0%);
}
</style>
