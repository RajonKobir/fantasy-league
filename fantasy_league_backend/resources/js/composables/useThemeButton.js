import { computed } from 'vue'
import { usePage } from '@inertiajs/vue3'

/**
 * Composable to get dynamically themed button classes based on theme color
 */
export const useThemeButton = () => {
  const page = usePage()
  const themeColor = computed(() => page.props.settings?.theme_color || '#3b82f6')

  const getPrimaryButtonClass = () => {
    return 'bg-theme text-white rounded-lg hover:opacity-90 transition-opacity disabled:opacity-50 disabled:cursor-not-allowed font-medium'
  }

  const getSecondaryButtonClass = () => {
    return 'bg-gray-200 text-gray-800 rounded-lg hover:bg-gray-300 transition-colors disabled:opacity-50 disabled:cursor-not-allowed font-medium'
  }

  const getDangerButtonClass = () => {
    return 'bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed font-medium'
  }

  const getSuccessButtonClass = () => {
    return 'bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed font-medium'
  }

  return {
    themeColor,
    getPrimaryButtonClass,
    getSecondaryButtonClass,
    getDangerButtonClass,
    getSuccessButtonClass,
  }
}
