<script setup>
import { Link } from '@inertiajs/vue3'
import { ref, computed, onMounted, watch, onUnmounted } from 'vue'
import { usePage } from '@inertiajs/vue3'
import { useThemeColor } from '@/composables/useThemeColor'

const mobileOpen = ref(false)
const page = usePage()
const expandedMenu = ref({})
const profileDropdownOpen = ref(false)

// Initialize theme and font from composable
const { themeColor, fontFamily } = useThemeColor()

// Set CSS variables on mount
onMounted(() => {
  const themeColorValue = page.props.settings?.theme_color || themeColor.value || '#3b82f6'
  document.documentElement.style.setProperty('--theme-color', themeColorValue)
  const fontFamilyValue = page.props.settings?.font_family || fontFamily.value || 'system-ui'
  const fontMap = {
    'system-ui': 'system-ui',
    'inter': '"Inter", -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif',
    'roboto': '"Roboto", -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif',
    'poppins': '"Poppins", -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif',
    'ubuntu': '"Ubuntu", -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif',
    'georgia': '"Georgia", serif',
  }
  document.documentElement.style.setProperty('--font-family', fontMap[fontFamilyValue] || fontMap['system-ui'])

  // Auto-expand menus with active submenu items
  menuItems.forEach((item, index) => {
    if (item.submenu && item.submenu.some(sub => isActive(sub.href))) {
      expandedMenu.value[index] = true
    }
  })
})

const user = computed(() => page.props.auth?.user || {})

const menuItems = [
  { label: 'Dashboard', href: '/admin/dashboard', icon: '📊' },
  {
    label: 'Users',
    icon: '👨‍💼',
    submenu: [
      { label: 'All Users', href: '/admin/users' },
      { label: 'Admins', href: '/admin/admins' }
    ]
  },
  {
    label: 'Payments',
    icon: '💳',
    submenu: [
      { label: 'Payment Requests', href: '/admin/payment-requests' },
      { label: 'Payment Methods', href: '/admin/payment-methods' }
    ]
  },
  {
    label: 'Players',
    icon: '🏏',
    submenu: [
      { label: 'All Players', href: '/admin/players' },
      { label: 'Player Roles', href: '/admin/player-roles' }
    ]
  },
  { label: 'Teams', href: '/admin/teams', icon: '🎯' },
  { label: 'Tournaments', href: '/admin/tournaments', icon: '🏆' },
  { label: 'Game Matches', href: '/admin/game-matches', icon: '🔥' },
  {
    label: 'Fantasy Teams',
    icon: '⭐',
    submenu: [
      { label: 'All Teams', href: '/admin/fantasy-teams' },
      { label: 'Cancel Requests', href: '/admin/cancel-requests' }
    ]
  },
  { label: 'Match Points', href: '/admin/points', icon: '📈' },
  {
    label: 'Winners',
    icon: '🏅',
    submenu: [
      { label: 'All Winners', href: '/admin/winners' },
      { label: 'Winners Management', href: '/admin/winners/manage' }
    ]
  },
  { label: 'Settings', href: '/admin/settings', icon: '⚙️' },
]

const isActive = (href) => {
  return page.url.startsWith(href)
}

const toggleMenu = (index) => {
  expandedMenu.value[index] = !expandedMenu.value[index]
}

const isMenuExpanded = (index) => {
  return expandedMenu.value[index] || false
}

const hasActiveSubmenu = (item) => {
  if (!item.submenu) return false
  return item.submenu.some(sub => isActive(sub.href))
}

// Close mobile menu on Escape
const _onKeydown = (e) => {
  if (e.key === 'Escape' && mobileOpen.value) {
    mobileOpen.value = false
  }
}

watch(mobileOpen, (val) => {
  if (val) {
    document.addEventListener('keydown', _onKeydown)
    // Prevent body scrolling while the mobile drawer is open
    document.body.style.overflow = 'hidden'
  } else {
    document.removeEventListener('keydown', _onKeydown)
    document.body.style.overflow = ''
  }
})

onUnmounted(() => {
  document.removeEventListener('keydown', _onKeydown)
  document.body.style.overflow = ''
})
</script>

<template>
  <div class="flex h-screen bg-gray-50">
    <!-- Sidebar (hidden on mobile and tablet, shown on lg+) -->
    <aside class="hidden lg:flex flex-col w-64 bg-gradient-to-b from-blue-900 to-blue-800 shadow-2xl">
      <!-- Logo -->
      <div class="p-6 border-b border-blue-700">
        <div class="text-2xl font-bold text-white flex items-center gap-2">
          🏏 <span>Fantasy League</span>
        </div>
        <p class="text-blue-200 text-xs mt-1">Admin Dashboard</p>
      </div>

      <!-- Navigation -->
      <nav class="flex-1 p-4 space-y-1 overflow-y-auto">
        <template v-for="(item, index) in menuItems" :key="item.href || index">
          <!-- Item with submenu -->
          <template v-if="item.submenu">
            <button
              @click="toggleMenu(index)"
              :class="{
                'bg-blue-700 text-white shadow-lg': isMenuExpanded(index) || hasActiveSubmenu(item),
                'text-blue-100 hover:bg-blue-700': !isMenuExpanded(index) && !hasActiveSubmenu(item)
              }"
              class="w-full flex items-center gap-3 px-4 py-3 rounded-lg transition-all duration-200 font-medium"
            >
              <span class="text-xl">{{ item.icon }}</span>
              <span class="flex-1 text-left">{{ item.label }}</span>
              <span class="text-lg">
                <svg v-if="isMenuExpanded(index) || hasActiveSubmenu(item)" class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
                  <path fill-rule="evenodd" d="M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z" clip-rule="evenodd" />
                </svg>
                <svg v-else class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
                  <path fill-rule="evenodd" d="M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z" clip-rule="evenodd" />
                </svg>
              </span>
            </button>
            <!-- Submenu items -->
            <template v-if="isMenuExpanded(index) || hasActiveSubmenu(item)">
              <Link
                v-for="sub in item.submenu"
                :key="sub.href"
                :href="sub.href"
                :class="{
                  'bg-blue-600 text-white': isActive(sub.href),
                  'text-blue-100 hover:bg-blue-700': !isActive(sub.href)
                }"
                class="flex items-center gap-3 px-4 py-2 ml-4 rounded-lg transition-all duration-200 text-sm"
              >
                <span class="text-blue-300 text-lg">•</span>
                <span>{{ sub.label }}</span>
              </Link>
            </template>
          </template>
          <!-- Regular item without submenu -->
          <template v-else>
            <Link
              :href="item.href"
              :class="{
                'bg-blue-700 text-white shadow-lg': isActive(item.href),
                'text-blue-100 hover:bg-blue-700': !isActive(item.href)
              }"
              class="flex items-center gap-3 px-4 py-3 rounded-lg transition-all duration-200 font-medium"
            >
              <span class="text-xl">{{ item.icon }}</span>
              <span>{{ item.label }}</span>
            </Link>
          </template>
        </template>
      </nav>
    </aside>

    <!-- Content area -->
    <div class="flex-1 flex flex-col">
      <!-- Mobile header + actions -->
      <header class="lg:hidden bg-gradient-to-r from-blue-900 to-blue-800 border-b shadow-lg p-3 sm:p-4 flex items-center justify-between text-white">
        <div class="flex items-center gap-3">
          <button
            @click="mobileOpen = !mobileOpen"
            :aria-expanded="mobileOpen"
            aria-controls="mobile-navigation"
            aria-label="Toggle navigation"
            class="p-2 w-9 h-9 rounded-md bg-transparent text-white hover:bg-white/10 flex items-center justify-center shadow-sm focus:outline-none focus:ring-2 focus:ring-white/30"
          >
            <span v-if="!mobileOpen" class="text-lg" aria-hidden>☰</span>
            <span v-else class="text-lg" aria-hidden>✕</span>
          </button>

          <div class="font-bold flex items-center gap-2 ml-1">
            <span class="hidden sm:inline">🏏</span>
            <span class="hidden sm:inline">Admin</span>
          </div>
        </div>

        <div class="flex items-center gap-3">
          <slot name="actions" />

          <div class="relative">
            <button
              @click="profileDropdownOpen = !profileDropdownOpen"
              aria-expanded="profileDropdownOpen"
              aria-label="Open profile menu"
              class="flex items-center gap-2 p-1 rounded-full bg-transparent hover:bg-white/5 focus:outline-none focus:ring-2 focus:ring-white/30"
            >
              <img
                :src="user.avatar_url || ('https://ui-avatars.com/api/?name=' + encodeURIComponent(user.name || 'Admin'))"
                :alt="user.name"
                class="w-7 h-7 rounded-full object-cover border-2 border-white"
              />
              <span class="hidden sm:inline text-sm font-medium text-white truncate max-w-[120px]">{{ user.name }}</span>
            </button>

            <!-- Mobile profile dropdown -->
            <div
              v-if="profileDropdownOpen"
              @click.outside="profileDropdownOpen = false"
              class="absolute right-0 mt-3 w-44 bg-white rounded-lg shadow-xl border z-50 text-left"
            >
              <Link href="/admin/profile" class="flex items-center gap-3 px-4 py-3 text-gray-700 hover:bg-gray-50" @click="profileDropdownOpen = false">
                <span>👤</span>
                <span>My Profile</span>
              </Link>
              <form method="post" action="/logout">
                <button type="submit" class="w-full text-left px-4 py-3 text-red-600 hover:bg-red-50">🚪 Logout</button>
              </form>
            </div>
          </div>
        </div>
      </header>

      <!-- Mobile nav drawer (off-canvas) -->
      <transition name="slide">
        <div v-if="mobileOpen" class="lg:hidden fixed inset-0 z-40 flex">
          <!-- Backdrop -->
          <div class="fixed inset-0 bg-black bg-opacity-50" @click="mobileOpen = false" aria-hidden="true"></div>

          <!-- Drawer -->
          <nav id="mobile-navigation" class="relative bg-white w-64 h-full shadow-lg p-4 overflow-y-auto" role="navigation" aria-label="Mobile primary">
            <div class="flex items-center justify-between mb-4">
              <div class="font-bold flex items-center gap-2">
                <span>🏏</span>
                <span>Admin</span>
              </div>
              <button @click="mobileOpen = false" aria-label="Close navigation" class="p-2 rounded-lg hover:bg-gray-100">✕</button>
            </div>

            <template v-for="(item, index) in menuItems" :key="item.href || index">
              <!-- Item with submenu -->
              <template v-if="item.submenu">
                <button
                  @click="toggleMenu(index)"
                  :class="{
                    'bg-blue-600 text-white': isMenuExpanded(index) || hasActiveSubmenu(item),
                    'text-gray-700 hover:bg-gray-100': !isMenuExpanded(index) && !hasActiveSubmenu(item)
                  }"
                  class="w-full flex items-center gap-3 px-4 py-2 rounded-lg transition-all"
                >
                  <span>{{ item.icon }}</span>
                  <span class="flex-1 text-left">{{ item.label }}</span>
                  <span class="text-lg">
                    <svg v-if="isMenuExpanded(index) || hasActiveSubmenu(item)" class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
                      <path fill-rule="evenodd" d="M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z" clip-rule="evenodd" />
                    </svg>
                    <svg v-else class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
                      <path fill-rule="evenodd" d="M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z" clip-rule="evenodd" />
                    </svg>
                  </span>
                </button>
                <!-- Mobile submenu items -->
                <template v-if="isMenuExpanded(index) || hasActiveSubmenu(item)">
                  <Link
                    v-for="sub in item.submenu"
                    :key="sub.href"
                    :href="sub.href"
                    @click="mobileOpen = false"
                    :class="{
                      'bg-blue-100 text-blue-600': isActive(sub.href),
                      'text-gray-700 hover:bg-gray-100': !isActive(sub.href)
                    }"
                    class="flex items-center gap-3 px-4 py-2 ml-4 rounded-lg transition-all text-sm"
                  >
                    <span class="text-blue-500">•</span>
                    <span>{{ sub.label }}</span>
                  </Link>
                </template>
              </template>
              <!-- Regular item without submenu -->
              <template v-else>
                <Link
                  :href="item.href"
                  @click="mobileOpen = false"
                  :class="{
                    'bg-blue-600 text-white': isActive(item.href),
                    'text-gray-700 hover:bg-gray-100': !isActive(item.href)
                  }"
                  class="flex items-center gap-3 px-4 py-2 rounded-lg transition-all"
                >
                  <span>{{ item.icon }}</span>
                  <span>{{ item.label }}</span>
                </Link>
              </template>
            </template>

            <hr class="my-2" />
            <Link
              href="/logout"
              method="post"
              as="button"
              @click="mobileOpen = false"
              class="w-full flex items-center gap-3 px-4 py-2 rounded-lg text-red-600 hover:bg-red-100"
            >
              <span>🚪</span>
              <span>Logout</span>
            </Link>
          </nav>
        </div>
      </transition>

      <!-- Desktop header with actions -->
      <div class="hidden lg:flex items-center justify-between p-6 bg-white border-b shadow-sm">
        <div></div>
        <div class="flex items-center gap-6">
          <slot name="actions" />
          <!-- Profile dropdown -->
          <div class="relative">
            <button
              @click="profileDropdownOpen = !profileDropdownOpen"
              class="flex items-center gap-3 p-2 rounded-lg hover:bg-gray-100 transition"
            >
              <img
                :src="user.avatar_url || 'https://ui-avatars.com/api/?name=' + encodeURIComponent(user.name || 'Admin')"
                :alt="user.name"
                class="w-10 h-10 rounded-full object-cover border-2 border-blue-500"
              />
              <div class="text-left hidden sm:block">
                <p class="text-sm font-semibold text-gray-900">{{ user.name }}</p>
                <p class="text-xs text-gray-500">{{ user.email }}</p>
              </div>
            </button>

            <!-- Dropdown menu -->
            <div
              v-if="profileDropdownOpen"
              @click.outside="profileDropdownOpen = false"
              class="absolute right-0 mt-2 w-48 bg-white rounded-lg shadow-xl border border-gray-200 z-50"
            >
              <Link
                href="/admin/profile"
                class="flex items-center gap-3 px-4 py-3 text-gray-700 hover:bg-gray-50 transition border-b"
              >
                <span>👤</span>
                <span>My Profile</span>
              </Link>
              <Link
                href="/logout"
                method="post"
                as="button"
                class="w-full flex items-center gap-3 px-4 py-3 text-red-600 hover:bg-red-50 transition text-left"
              >
                <span>🚪</span>
                <span>Logout</span>
              </Link>
            </div>
          </div>
        </div>
      </div>

      <!-- Main content -->
      <main class="flex-1 flex flex-col overflow-hidden">
        <div class="flex-1 overflow-y-auto overflow-x-hidden">
          <!-- Responsive inner container: full width on mobile, constrained on larger screens -->
          <div class="w-full px-3 sm:px-4 md:px-6 lg:px-8 py-4 sm:py-6">
            <slot />
          </div>
        </div>

        <!-- Footer -->
        <footer class="bg-gray-100 border-t border-gray-200 py-4 px-4 sm:px-6 text-center text-gray-600 text-xs sm:text-sm">
          <p>&copy; {{ new Date().getFullYear() }} Fantasy League. All rights reserved.</p>
        </footer>
      </main>
    </div>
  </div>
</template>

<style scoped>
/* Apply CSS variables for theme and font */
:root {
  --theme-color: v-bind('themeColor');
  --font-family: v-bind('fontFamily');
}

:deep(*) {
  font-family: var(--font-family, system-ui);
}

/* Apply theme color to primary elements */
:deep(.bg-blue-600) {
  background-color: var(--theme-color, #2563eb);
}

:deep(.bg-blue-700) {
  background-color: var(--theme-color, #1d4ed8);
}

:deep(.border-blue-500) {
  border-color: var(--theme-color, #3b82f6);
}

:deep(.text-blue-600) {
  color: var(--theme-color, #2563eb);
}

:deep(.focus\\:border-blue-500:focus) {
  border-color: var(--theme-color, #3b82f6);
}

:deep(.focus\\:ring-blue-500:focus) {
  --tw-ring-color: var(--theme-color, #3b82f6);
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
