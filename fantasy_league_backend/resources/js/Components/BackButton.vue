<script setup>
import { Link } from '@inertiajs/vue3'

defineProps({
  href: { type: String, required: true },
  label: { type: String, default: 'Back' }
})
</script>

<template>
  <Link
    :href="href"
    class="text-sm text-gray-600 hover:text-gray-900 underline"
  >
    ⬅ {{ label }}
  </Link>
</template>
