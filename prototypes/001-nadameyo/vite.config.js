import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import { languageApiPlugin } from './server/localModel.js'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react(), languageApiPlugin()],
})
