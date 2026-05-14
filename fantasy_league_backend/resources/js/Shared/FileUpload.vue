<template>
  <div>
    <label class="block text-sm font-medium mb-1">{{ label }}</label>

    <div
      class="border-2 border-dashed rounded p-4 text-center cursor-pointer transition-colors duration-200 ease-in-out"
      :class="{
        'border-blue-500 bg-blue-50 shadow-sm scale-105': isDragOver,
        'border-gray-200 bg-white hover:bg-gray-50': !isDragOver
      }
      "
      @click="openDialog"
      @dragover.prevent="isDragOver = true"
      @dragenter.prevent="isDragOver = true"
      @dragleave.prevent="isDragOver = false"
      @drop.prevent="onDrop"
    >
      <input ref="inputRef" type="file" :accept="accept" class="hidden" @change="onInputChange" />

      <div v-if="preview" class="flex flex-col items-center gap-2">
        <img :src="preview" class="mx-auto h-24 w-24 sm:h-28 sm:w-28 object-cover rounded transition-transform duration-150 hover:scale-105" />
        <div class="text-xs text-gray-600 truncate max-w-full">{{ selectedFile ? selectedFile.name : 'Selected image' }}</div>
      </div>

      <div v-else>
        <p class="text-sm text-gray-500">Drag & drop here, or click to select</p>
        <p class="text-xs text-gray-400 mt-1">Accepted: {{ accept }} · Max: {{ maxSizeMB }}MB</p>
      </div>

      <div v-if="error" class="mt-2 text-sm text-red-600">{{ error }}</div>

      <div v-if="progress > 0" class="mt-3">
        <div class="bg-gray-200 rounded h-2 w-full overflow-hidden">
          <div class="bg-blue-600 h-2" :style="{ width: progress + '%' }"></div>
        </div>
        <div class="text-xs text-gray-600 mt-1">{{ progress }}%</div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, watch } from 'vue'

const props = defineProps({
  accept: { type: String, default: 'image/*' },
  label: { type: String, default: 'File' },
  maxSizeMB: { type: Number, default: 3 },
  initialPreview: { type: String, default: null },
  progress: { type: Number, default: 0 },
})
const emit = defineEmits(['file-changed'])

const inputRef = ref(null)
const isDragOver = ref(false)
const selectedFile = ref(null)
const preview = ref(props.initialPreview)
const error = ref(null)

watch(selectedFile, (v) => {
  // expose filename in template
})

watch(() => props.initialPreview, (v) => preview.value = v)
watch(() => props.progress, (v) => {
  /* no-op here, prop drives template */
})

function openDialog() {
  inputRef.value && inputRef.value.click()
}

function onInputChange(e) {
  handleFile(e.target.files[0])
}

function onDrop(e) {
  isDragOver.value = false
  handleFile(e.dataTransfer.files[0])
}

function handleFile(file) {
  if (!file) {
    selectedFile.value = null
    preview.value = props.initialPreview
    emit('file-changed', null)
    return
  }

  if (props.accept.startsWith('image') && !file.type.startsWith('image')) {
    error.value = 'Invalid file type — please upload an image.'
    return
  }

  if (file.size > props.maxSizeMB * 1024 * 1024) {
    error.value = `File must be smaller than ${props.maxSizeMB}MB.`
    return
  }

  // small responsiveness improvement for very small images
  error.value = null
  selectedFile.value = file
  preview.value = URL.createObjectURL(file)
  // small debounce to avoid flashing progress on tiny uploads
  setTimeout(() => emit('file-changed', file), 50)
}
</script>

<style scoped>
/* small hover/drag styles could go here if needed */
</style>
