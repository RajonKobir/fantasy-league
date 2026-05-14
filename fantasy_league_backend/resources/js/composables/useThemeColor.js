import { ref, computed } from 'vue'

// Store theme settings in reactive refs
const themeColor = ref(localStorage.getItem('theme_color') || '#3b82f6')
const fontFamily = ref(localStorage.getItem('font_family') || 'system-ui')

// Font family mappings
const fontFamilyMap = {
  'system-ui': 'system-ui',
  'inter': '"Inter", -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif',
  'roboto': '"Roboto", -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif',
  'poppins': '"Poppins", -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif',
  'ubuntu': '"Ubuntu", -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif',
  'georgia': '"Georgia", serif',
}

/**
 * Composable to access and manage theme color and font family
 * @returns {{ themeColor, fontFamily, setThemeColor, setFontFamily }}
 */
export const useThemeColor = () => {
  const setThemeColor = (color) => {
    themeColor.value = color
    localStorage.setItem('theme_color', color)
    // Apply to CSS custom property for global usage
    document.documentElement.style.setProperty('--theme-color', color)
  }

  const setFontFamily = (family) => {
    fontFamily.value = family
    localStorage.setItem('font_family', family)
    // Apply to CSS custom property for global usage
    const fontStack = fontFamilyMap[family] || fontFamilyMap['system-ui']
    document.documentElement.style.setProperty('--font-family', fontStack)
  }

  // Initialize on load
  if (typeof window !== 'undefined') {
    document.documentElement.style.setProperty('--theme-color', themeColor.value)
    const fontStack = fontFamilyMap[fontFamily.value] || fontFamilyMap['system-ui']
    document.documentElement.style.setProperty('--font-family', fontStack)
  }

  return {
    themeColor: computed(() => themeColor.value),
    fontFamily: computed(() => fontFamily.value),
    setThemeColor,
    setFontFamily,
  }
}
