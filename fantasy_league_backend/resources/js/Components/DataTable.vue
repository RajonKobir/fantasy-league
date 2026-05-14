<script setup>
import { Link } from '@inertiajs/vue3'

defineProps({
  title: String,
  icon: String,
  description: String,
  items: Object,
  columns: Array,
  actions: Array,
  searchPlaceholder: String,
  filters: Object,
})

const emits = defineEmits(['delete'])

const handleDelete = (itemId, itemName) => {
  if (confirm(`Delete "${itemName}"? This action cannot be undone.`)) {
    emits('delete', itemId)
  }
}

const getCellValue = (item, column) => {
  const keys = column.key.split('.')
  let value = item
  for (const key of keys) {
    value = value?.[key]
  }
  return value
}
</script>

<template>
  <div class="space-y-6">
    <!-- Header -->
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
      <div>
        <h1 class="text-3xl font-bold text-gray-900">
          <span v-if="icon">{{ icon }} </span>{{ title }}
        </h1>
        <p v-if="description" class="text-gray-600 mt-1">{{ description }}</p>
      </div>
      <div class="flex gap-2">
        <Link href="/admin/dashboard" class="px-4 py-2 bg-gray-200 text-gray-800 rounded-lg hover:bg-gray-300 transition-colors font-semibold">
          ⬅ Back
        </Link>
      </div>
    </div>

    <!-- Search and Filter -->
    <div class="bg-white rounded-xl shadow-lg p-6">
      <form method="get" class="space-y-4">
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label class="block text-sm font-semibold text-gray-700 mb-2">🔍 Search</label>
            <input
              name="q"
              :value="filters?.q || ''"
              :placeholder="searchPlaceholder || 'Search...'"
              class="w-full px-4 py-2 border-2 border-gray-200 rounded-lg focus:border-blue-500 focus:outline-none transition-colors"
            />
          </div>
          <div>
            <label class="block text-sm font-semibold text-gray-700 mb-2">📊 Per Page</label>
            <select
              name="per_page"
              :value="filters?.per_page || 15"
              class="w-full px-4 py-2 border-2 border-gray-200 rounded-lg focus:border-blue-500 focus:outline-none transition-colors"
            >
              <option value="10">10 items</option>
              <option value="15">15 items</option>
              <option value="25">25 items</option>
              <option value="50">50 items</option>
            </select>
          </div>
        </div>
        <div class="flex gap-2 justify-end">
          <Link href="" class="px-4 py-2 border-2 border-gray-300 text-gray-700 rounded-lg hover:bg-gray-100 transition-colors font-semibold">
            Clear
          </Link>
          <button type="submit" class="px-6 py-2 bg-gradient-to-r from-blue-600 to-blue-700 text-white rounded-lg hover:from-blue-700 hover:to-blue-800 transition-all font-semibold shadow-lg">
            🔍 Search
          </button>
        </div>
      </form>
    </div>

    <!-- Data Table -->
    <div class="bg-white rounded-xl shadow-lg overflow-hidden hover:shadow-xl transition-shadow">
      <div class="overflow-x-auto">
        <table class="w-full">
          <thead>
            <tr class="bg-gradient-to-r from-gray-100 to-gray-50 border-b-2 border-gray-200">
              <th v-for="column in columns" :key="column.key" class="px-6 py-4 text-left text-xs font-bold text-gray-600 uppercase tracking-wider">
                {{ column.label }}
              </th>
              <th class="px-6 py-4 text-left text-xs font-bold text-gray-600 uppercase tracking-wider">Actions</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-200">
            <tr v-for="item in items.data" :key="item.id" class="hover:bg-blue-50 transition-colors">
              <td v-for="column in columns" :key="column.key" class="px-6 py-4">
                <component
                  v-if="column.render"
                  :is="column.render"
                  :value="getCellValue(item, column)"
                  :item="item"
                />
                <span v-else>{{ getCellValue(item, column) }}</span>
              </td>
              <td class="px-6 py-4">
                <div class="flex gap-2 flex-wrap">
                  <template v-for="action in actions" :key="action.label">
                    <Link
                      v-if="action.href"
                      :href="action.href(item)"
                      class="px-3 py-1.5 bg-blue-100 text-blue-700 rounded-lg hover:bg-blue-200 transition-colors text-sm font-semibold"
                    >
                      {{ action.label }}
                    </Link>
                    <button
                      v-else-if="action.delete"
                      @click="handleDelete(item.id, item.name || item.email)"
                      class="px-3 py-1.5 bg-red-100 text-red-700 rounded-lg hover:bg-red-200 transition-colors text-sm font-semibold"
                    >
                      {{ action.label }}
                    </button>
                  </template>
                </div>
              </td>
            </tr>
            <tr v-if="items.data.length === 0">
              <td :colspan="columns.length + 1" class="px-6 py-12 text-center">
                <div class="flex flex-col items-center gap-3 text-gray-500">
                  <span class="text-4xl">📭</span>
                  <p class="text-lg font-semibold">No items found</p>
                  <p class="text-sm">Try adjusting your search filters</p>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Pagination -->
    <div class="flex items-center justify-between pt-4">
      <p class="text-sm text-gray-600">
        Showing {{ items.from || 0 }} to {{ items.to || 0 }} of {{ items.total }} items
      </p>
      <div class="flex gap-2">
        <Link
          v-if="items.prev_page_url"
          :href="items.prev_page_url"
          class="px-4 py-2 bg-gray-200 text-gray-800 rounded-lg hover:bg-gray-300 transition-colors font-semibold"
        >
          ⬅ Previous
        </Link>
        <Link
          v-if="items.next_page_url"
          :href="items.next_page_url"
          class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors font-semibold"
        >
          Next ➡
        </Link>
      </div>
    </div>
  </div>
</template>
