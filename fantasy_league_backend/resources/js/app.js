import '../css/app.css'
import './bootstrap'

import { createApp, h } from 'vue'
import { createInertiaApp } from '@inertiajs/vue3'
import { resolvePageComponent } from 'laravel-vite-plugin/inertia-helpers'
import { ZiggyVue } from '../../vendor/tightenco/ziggy';

import toast from "vue3-toastify"
import "vue3-toastify/dist/index.css"

const appName = import.meta.env.VITE_APP_NAME || 'Laravel'

createInertiaApp({
    title: (title) => title ? `${title} - ${appName}` : appName,

    resolve: (name) =>
        resolvePageComponent(
            `./Pages/${name}.vue`,
            import.meta.glob('./Pages/**/*.vue')
        ),

    setup({ el, App, props, plugin }) {
        const vueApp = createApp({ render: () => h(App, props) })
        // Global error handler to surface setup/runtime errors in console and toast
        vueApp.config.errorHandler = (err, vm, info) => {
            // Log detailed info to console
            console.error('Vue Global Error:', err)
            console.error('Component:', vm)
            console.error('Info:', info)
            // show a user-visible toast (gentle)
            try { vueApp.config.globalProperties.$toast.error(`UI error: ${err.message || 'See console'}`) } catch (e) { /* ignore */ }
        }

        // Unhandled promise rejections
        window.addEventListener('unhandledrejection', (ev) => {
            console.error('Unhandled Promise Rejection:', ev.reason)
            try { vueApp.config.globalProperties.$toast.error(`Unhandled Promise Rejection: ${ev.reason?.message || 'See console'}`) } catch (e) { /* ignore */ }
        })

        vueApp.use(plugin)
        vueApp.use(ZiggyVue)
        vueApp.use(toast)
        vueApp.mount(el)
    },


    progress: {
        color: '#4B5563',
    },
})
