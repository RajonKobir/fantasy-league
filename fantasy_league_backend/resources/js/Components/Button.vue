<script setup>
defineProps({
  variant: {
    type: String,
    default: 'primary'
  },
  size: {
    type: String,
    default: 'md'
  },
  icon: String,
})

const variants = {
  primary: 'bg-gradient-to-r from-blue-600 to-blue-700 text-white hover:from-blue-700 hover:to-blue-800 shadow-lg hover:shadow-xl',
  secondary: 'bg-gray-200 text-gray-800 hover:bg-gray-300',
  success: 'bg-gradient-to-r from-green-600 to-green-700 text-white hover:from-green-700 hover:to-green-800 shadow-lg hover:shadow-xl',
  danger: 'bg-gradient-to-r from-red-600 to-red-700 text-white hover:from-red-700 hover:to-red-800 shadow-lg hover:shadow-xl',
  outline: 'border-2 border-blue-600 text-blue-600 hover:bg-blue-50',
}

const sizes = {
  sm: 'px-3 py-1.5 text-sm',
  md: 'px-4 py-2 text-base',
  lg: 'px-6 py-3 text-lg',
}

const variantClass = variants[variant] || variants.primary
const sizeClass = sizes[size] || sizes.md
</script>

<template>
  <button :class="`${variantClass} ${sizeClass} rounded-lg font-semibold transition-all duration-200 inline-flex items-center gap-2 disabled:opacity-50 disabled:cursor-not-allowed`">
    <span v-if="icon">{{ icon }}</span>
    <slot />
  </button>
</template>
