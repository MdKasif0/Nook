import { defineConfig } from 'vite';

export default defineConfig({
  build: {
    outDir: 'dist-web',
    emptyOutDir: true,
    chunkSizeWarningLimit: 1000
  },
  server: {
    host: true,
    port: 3000,
    open: false
  }
});
