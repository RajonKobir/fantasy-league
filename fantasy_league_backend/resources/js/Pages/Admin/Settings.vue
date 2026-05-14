<script setup>
import { Head, Link, useForm } from '@inertiajs/vue3'
import AdminLayout from '@/Layouts/AdminLayout.vue'
import { ref, computed, onMounted } from 'vue'
import { useThemeColor } from '@/composables/useThemeColor'

defineOptions({
  layout: AdminLayout,
})

const { settings } = defineProps({
  settings: Object,
})

const { setThemeColor, setFontFamily } = useThemeColor()

const fontFamilies = [
  { value: 'system-ui', label: '🖥️ System Default', preview: 'system-ui' },
  { value: 'inter', label: '📝 Inter', preview: "'Inter', sans-serif" },
  { value: 'roboto', label: '📝 Roboto', preview: "'Roboto', sans-serif" },
  { value: 'poppins', label: '📝 Poppins', preview: "'Poppins', sans-serif" },
  { value: 'ubuntu', label: '📝 Ubuntu', preview: "'Ubuntu', sans-serif" },
  { value: 'georgia', label: '📝 Georgia', preview: "'Georgia', serif" },
]

const form = useForm({
  settings: {
    theme_color: settings.theme_color || '#3b82f6',
    font_family: settings.font_family || 'system-ui',
    // App version enforcement
    min_app_version: settings.min_app_version || '',
    force_update: settings.force_update ? (settings.force_update == '1' || settings.force_update === true) : false,
    update_url: settings.update_url || '',
  },
})

const errors = ref({})
const isSubmitting = ref(false)
const deletingKey = ref(null)

const themeColorPreview = computed(() => form.settings.theme_color)

// Apply current settings on mount
onMounted(() => {
  setThemeColor(form.settings.theme_color)
  setFontFamily(form.settings.font_family)
})

function submit() {
  errors.value = {}
  isSubmitting.value = true

  form.post(route('admin.settings.update'), {
    onError: (err) => {
      Object.assign(errors.value, err)
    },
    onSuccess: () => {
      // Apply the new theme and font family immediately after saving
      setThemeColor(form.settings.theme_color)
      setFontFamily(form.settings.font_family)
    },
    onFinish: () => {
      isSubmitting.value = false
    },
  })
}

function deleteSetting(key) {
  if (confirm(`Are you sure you want to delete the "${key}" setting?`)) {
    const deleteForm = useForm({ key })
    deleteForm.post(route('admin.settings.delete'), {
      onFinish: () => {
        deletingKey.value = null
      },
    })
  }
}
</script>

<template>
  <Head title="Admin Settings" />

  <div class="space-y-8">
    <!-- Header -->
    <div>
      <h1 class="text-4xl font-bold text-gray-900">⚙️ Application Settings</h1>
      <p class="text-gray-600 mt-2">Configure global application settings</p>
    </div>

    <!-- Settings Cards -->
    <div class="space-y-6">
      <!-- Theme Color & Font Family Settings -->
      <div class="bg-white rounded-xl shadow-lg p-8">
        <div class="mb-6">
          <h2 class="text-2xl font-bold text-gray-900 mb-2">⚙️ Appearance Settings</h2>
          <p class="text-gray-600">Customize the admin panel theme and typography</p>
        </div>

        <div class="space-y-8">
          <!-- Theme Color Setting -->
          <div>
            <h3 class="text-lg font-semibold text-gray-800 mb-4">Theme Color</h3>
            <div class="flex items-center gap-6">
              <div class="flex-1">
                <label class="block text-sm font-medium text-gray-700 mb-2">Select Color</label>
                <div class="flex gap-3">
                  <input
                    v-model="form.settings.theme_color"
                    @input="setThemeColor(form.settings.theme_color)"
                    type="color"
                    class="w-20 h-20 border-2 border-gray-300 rounded-lg cursor-pointer"
                  />
                  <input
                    v-model="form.settings.theme_color"
                    @input="setThemeColor(form.settings.theme_color)"
                    type="text"
                    class="flex-1 px-4 py-2 border-2 border-gray-300 rounded-lg focus:outline-none focus:border-blue-500"
                    placeholder="#3b82f6"
                  />
                </div>
                <p v-if="errors.theme_color" class="mt-2 text-sm text-red-600">{{ errors.theme_color }}</p>
              </div>

              <!-- Color Preview -->
              <div class="flex-shrink-0">
                <p class="text-sm font-medium text-gray-700 mb-2">Preview</p>
                <div
                  class="w-24 h-24 rounded-lg shadow border-2 border-gray-200 transition-all"
                  :style="{ backgroundColor: themeColorPreview }"
                />
              </div>
            </div>
          </div>

          <!-- App Version Enforcement -->
          <div class="border-t pt-8">
            <h3 class="text-lg font-semibold text-gray-800 mb-4">📱 App Version Enforcement</h3>
            <p class="text-sm text-gray-600 mb-4">Configure minimum supported app version and whether older versions should be forced to update.</p>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-2">Minimum App Version</label>
                <input
                  v-model="form.settings.min_app_version"
                  type="text"
                  class="w-full px-4 py-2 border-2 border-gray-300 rounded-lg focus:outline-none focus:border-blue-500"
                  placeholder="e.g. 1.2.0"
                />
                <p v-if="errors.min_app_version" class="mt-2 text-sm text-red-600">{{ errors.min_app_version }}</p>
              </div>

              <div>
                <label class="block text-sm font-medium text-gray-700 mb-2">Force Update</label>
                <div class="flex items-center gap-3">
                  <input v-model="form.settings.force_update" type="checkbox" class="h-5 w-5" />
                  <p class="text-sm text-gray-600">When enabled, clients below the minimum version will be blocked from using the app until they update.</p>
                </div>
                <p v-if="errors.force_update" class="mt-2 text-sm text-red-600">{{ errors.force_update }}</p>
              </div>

              <div class="md:col-span-2">
                <label class="block text-sm font-medium text-gray-700 mb-2">Update URL</label>
                <input
                  v-model="form.settings.update_url"
                  type="text"
                  class="w-full px-4 py-2 border-2 border-gray-300 rounded-lg focus:outline-none focus:border-blue-500"
                  placeholder="https://play.google.com/store/apps/details?id=..."
                />
                <p v-if="errors.update_url" class="mt-2 text-sm text-red-600">{{ errors.update_url }}</p>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Form Actions -->
      <div class="flex gap-3">
        <button
          @click="submit"
          :disabled="isSubmitting"
          class="flex-1 px-6 py-3 btn-primary"
        >
          {{ isSubmitting ? 'Saving...' : '💾 Save Settings' }}
        </button>
        <Link
          href="/admin/dashboard"
          class="flex-1 px-6 py-3 bg-gray-200 text-gray-700 rounded-lg font-medium hover:bg-gray-300 text-center transition"
        >
          Cancel
        </Link>
      </div>
    </div>
  </div>
</template>
