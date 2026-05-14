<script setup>
import { computed } from 'vue'

const props = defineProps({
  label: String,
  value: [String, Number],
  icon: String,
  color: {
    type: String,
    default: 'blue'
  }
})

const colorClasses = {
  blue: 'bg-blue-50 border-blue-200 text-blue-600',
  green: 'bg-green-50 border-green-200 text-green-600',
  purple: 'bg-purple-50 border-purple-200 text-purple-600',
  amber: 'bg-amber-50 border-amber-200 text-amber-600',
  rose: 'bg-rose-50 border-rose-200 text-rose-600',
  cyan: 'bg-cyan-50 border-cyan-200 text-cyan-600',
}

const bgClass = computed(() => colorClasses[props.color] || colorClasses.blue)
</script>

<template>
  <div :class="`${bgClass} border rounded-xl shadow-sm hover:shadow-md transition-shadow p-6`">
    <div class="flex items-center justify-between">
      <div>
        <p class="text-sm font-medium opacity-75 mb-1">{{ label }}</p>
        <p class="text-3xl font-bold">{{ value }}</p>
      </div>
      <div class="text-4xl opacity-25">{{ icon }}</div>
    </div>
  </div>
</template>
