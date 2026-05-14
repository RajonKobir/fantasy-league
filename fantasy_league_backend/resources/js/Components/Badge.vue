<script setup>
defineProps({
  variant: {
    type: String,
    default: 'primary'
  },
  icon: String,
})

const variants = {
  primary: 'bg-blue-100 text-blue-800 border border-blue-300',
  success: 'bg-green-100 text-green-800 border border-green-300',
  danger: 'bg-red-100 text-red-800 border border-red-300',
  warning: 'bg-amber-100 text-amber-800 border border-amber-300',
  info: 'bg-cyan-100 text-cyan-800 border border-cyan-300',
  secondary: 'bg-gray-100 text-gray-800 border border-gray-300',
}

const variantClass = variants[variant] || variants.primary
</script>

<template>
  <span :class="`${variantClass} inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-bold`">
    <span v-if="icon">{{ icon }}</span>
    <slot />
  </span>
</template>
