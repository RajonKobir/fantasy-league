<script setup>
import { computed } from 'vue'

defineProps({
  title: String,
  subtitle: String,
  icon: String,
  padding: {
    type: String,
    default: 'lg'
  },
  shadow: {
    type: String,
    default: 'md'
  }
})

const paddingClass = {
  sm: 'p-4',
  md: 'p-6',
  lg: 'p-8',
}[padding] || 'p-6'

const shadowClass = {
  sm: 'shadow',
  md: 'shadow-lg',
  lg: 'shadow-xl',
}[shadow] || 'shadow-lg'
</script>

<template>
  <div :class="`bg-white rounded-xl ${shadowClass} hover:${shadowClass.replace('shadow', 'shadow-2xl')} transition-shadow overflow-hidden`">
    <!-- Header (optional) -->
    <div v-if="title || icon" class="bg-gradient-to-r from-blue-600 to-blue-700 text-white px-8 py-6">
      <div class="flex items-center gap-3">
        <span v-if="icon" class="text-3xl">{{ icon }}</span>
        <div>
          <h2 class="text-2xl font-bold">{{ title }}</h2>
          <p v-if="subtitle" class="text-blue-200 text-sm mt-1">{{ subtitle }}</p>
        </div>
      </div>
    </div>

    <!-- Content -->
    <div :class="paddingClass">
      <slot />
    </div>
  </div>
</template>
