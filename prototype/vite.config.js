import { defineConfig, loadEnv } from 'vite'
import react from '@vitejs/plugin-react'

// Browser apps can't call the Jellyfin API directly (CORS). In dev we proxy
// everything under /jf -> the Jellyfin server, so the client uses same-origin
// relative URLs and never trips CORS.
export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), '')
  const target = env.VITE_JELLYFIN_TARGET || 'http://192.168.50.19:8899'
  return {
    plugins: [react()],
    server: {
      host: true,
      proxy: {
        '/jf': {
          target,
          changeOrigin: true,
          secure: false,
          rewrite: (p) => p.replace(/^\/jf/, ''),
        },
      },
    },
  }
})
