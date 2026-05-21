import { resolve } from 'node:path';
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    strictPort: true,
  },
  build: {
    rollupOptions: {
      input: {
        main: resolve(__dirname, 'index.html'),
        about: resolve(__dirname, 'about.html'),
        programs: resolve(__dirname, 'programs.html'),
        resources: resolve(__dirname, 'resources.html'),
        support: resolve(__dirname, 'support.html'),
        start: resolve(__dirname, 'start.html'),
        contact: resolve(__dirname, 'contact.html'),
      },
    },
  },
});