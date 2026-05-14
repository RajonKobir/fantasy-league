<template>
  <div class="relative w-full">
    <!-- Input field -->
    <div class="relative">
      <input
        type="text"
        :placeholder="placeholder"
        v-model="searchQuery"
        @focus="isOpen = true"
        @blur="handleBlur"
        @keydown.escape="isOpen = false"
        @keydown.arrow-down.prevent="highlightNext"
        @keydown.arrow-up.prevent="highlightPrev"
        @keydown.enter.prevent="selectHighlighted"
        :class="[
          'w-full px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500',
          containerClass,
          isError ? 'border-red-500' : 'border-gray-300',
        ]"
      />
      <!-- Dropdown arrow icon -->
      <div class="absolute right-3 top-1/2 -translate-y-1/2 pointer-events-none">
        <svg
          class="w-5 h-5 text-gray-400 transition-transform"
          :class="{ 'rotate-180': isOpen }"
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
        >
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 14l-7 7m0 0l-7-7m7 7V3" />
        </svg>
      </div>
    </div>

    <!-- Dropdown menu -->
    <transition name="dropdown">
      <div
        v-if="isOpen && filteredOptions.length > 0"
        class="absolute z-50 w-full mt-1 bg-white border border-gray-300 rounded-lg shadow-lg max-h-60 overflow-y-auto"
      >
        <div
          v-for="(option, index) in filteredOptions"
          :key="option.id"
          @click="selectOption(option)"
          @mouseenter="highlightedIndex = index"
          :class="[
            'px-4 py-2 cursor-pointer transition-colors',
            index === highlightedIndex ? 'bg-blue-500 text-white' : 'hover:bg-gray-100',
            selectedValue === option.id ? 'font-semibold' : '',
          ]"
        >
          {{ option.label }}
        </div>
      </div>
    </transition>

    <!-- No results message -->
    <div
      v-if="isOpen && filteredOptions.length === 0 && searchQuery"
      class="absolute z-50 w-full mt-1 bg-white border border-gray-300 rounded-lg shadow-lg p-4 text-center text-gray-500"
    >
      No results found
    </div>

    <!-- Hidden input for form submission -->
    <input type="hidden" :name="name" :value="selectedValue" />
  </div>
</template>

<script setup>
import { ref, computed, watch } from 'vue'

const props = defineProps({
  modelValue: {
    type: [String, Number],
    default: '',
  },
  options: {
    type: Array,
    required: true,
    // Expected: [{ id, label }, ...]
  },
  placeholder: {
    type: String,
    default: 'Search...',
  },
  name: {
    type: String,
    default: 'search',
  },
  containerClass: {
    type: String,
    default: '',
  },
  isError: {
    type: Boolean,
    default: false,
  },
})

const emit = defineEmits(['update:modelValue'])

const searchQuery = ref('')
const isOpen = ref(false)
const highlightedIndex = ref(-1)

const selectedValue = computed(() => props.modelValue)

const selectedOption = computed(() => {
  return props.options.find((opt) => opt.id == props.modelValue)
})

const filteredOptions = computed(() => {
  if (!searchQuery.value.trim()) {
    return props.options
  }
  const query = searchQuery.value.toLowerCase()
  return props.options.filter((opt) => opt.label.toLowerCase().includes(query))
})

watch(selectedOption, (newOption) => {
  if (newOption) {
    searchQuery.value = newOption.label
  } else {
    searchQuery.value = ''
  }
}, { immediate: true })

const selectOption = (option) => {
  emit('update:modelValue', option.id)
  isOpen.value = false
  highlightedIndex.value = -1
}

const selectHighlighted = () => {
  if (highlightedIndex.value >= 0 && highlightedIndex.value < filteredOptions.value.length) {
    selectOption(filteredOptions.value[highlightedIndex.value])
  }
}

const highlightNext = () => {
  if (!isOpen.value) {
    isOpen.value = true
    highlightedIndex.value = 0
  } else if (highlightedIndex.value < filteredOptions.value.length - 1) {
    highlightedIndex.value++
  }
}

const highlightPrev = () => {
  if (highlightedIndex.value > 0) {
    highlightedIndex.value--
  }
}

const handleBlur = () => {
  setTimeout(() => {
    isOpen.value = false
  }, 200)
}
</script>

<style scoped>
.dropdown-enter-active,
.dropdown-leave-active {
  transition: opacity 0.15s ease, transform 0.15s ease;
}

.dropdown-enter-from,
.dropdown-leave-to {
  opacity: 0;
  transform: translateY(-8px);
}
</style>
