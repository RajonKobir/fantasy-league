<script setup>
import { computed } from 'vue'

const props = defineProps({
  items: {
    type: Array,
    required: true
  },
  columns: {
    type: Array,
    required: true
  },
  cardFields: {
    type: Array,
    required: true
  },
  emptyMessage: {
    type: String,
    default: 'No data found'
  }
})

const emit = defineEmits(['action'])
</script>

<template>
  <!-- Mobile: Card View (hidden on screens >= 768px) -->
  <div class="md:hidden space-y-3">
    <div
      v-for="(item, idx) in items"
      :key="idx"
      class="bg-white p-4 rounded-lg shadow border-l-4 border-blue-500 space-y-2"
    >
      <!-- Card fields -->
      <div v-for="field in cardFields" :key="field.key" class="text-sm">
        <span class="font-semibold text-gray-700">{{ field.label }}:</span>
        <span class="text-gray-900 ml-1">{{ item[field.key] }}</span>
      </div>
      <!-- Actions slot -->
      <div class="flex gap-2 pt-3 border-t flex-wrap">
        <slot name="actions" :item="item" :index="idx" />
      </div>
    </div>
    <div v-if="items.length === 0" class="text-center py-8 text-gray-500">
      {{ emptyMessage }}
    </div>
  </div>

  <!-- Desktop: Table View (hidden on screens < 768px) -->
  <div class="hidden md:block bg-white shadow rounded-lg overflow-x-auto">
    <table class="w-full text-sm">
      <thead class="bg-gray-50 border-b border-gray-200">
        <tr>
          <th
            v-for="col in columns"
            :key="col.key"
            class="px-6 py-3 text-left font-semibold text-gray-700 whitespace-nowrap"
          >
            {{ col.label }}
          </th>
          <th class="px-6 py-3 text-center font-semibold text-gray-700">Actions</th>
        </tr>
      </thead>
      <tbody class="divide-y divide-gray-200">
        <tr v-for="(item, idx) in items" :key="idx" class="hover:bg-gray-50 transition">
          <td
            v-for="col in columns"
            :key="col.key"
            class="px-6 py-4"
            :class="{ 'whitespace-nowrap': col.nowrap }"
          >
            <!-- Handle slot rendering -->
            <slot :name="`cell-${col.key}`" :value="item[col.key]" :item="item">
              {{ item[col.key] }}
            </slot>
          </td>
          <td class="px-6 py-4">
            <div class="flex gap-2 justify-center flex-wrap">
              <slot name="actions" :item="item" :index="idx" />
            </div>
          </td>
        </tr>
      </tbody>
    </table>
  </div>

  <div v-if="items.length === 0" class="hidden md:block text-center py-8 text-gray-500 bg-white">
    {{ emptyMessage }}
  </div>
</template>
