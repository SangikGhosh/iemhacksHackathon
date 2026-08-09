import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

import { defineConfig } from 'vite'
import react, { reactCompilerPreset } from '@vitejs/plugin-react'
import babel from '@rolldown/plugin-babel'
import tailwindcss from '@tailwindcss/vite'

const rootDir = path.dirname(fileURLToPath(import.meta.url))

const apkUrl = '/GreenRoute.apk'
const apkSource = path.resolve(
  rootDir,
  '../../mobile/greentech/build/app/outputs/apk/release/app-arm64-v8a-release.apk',
)

function flutterApk() {
  let outDir = 'dist'

  const serve = (req, res, next) => {
    if ((req.url ?? '').split('?')[0] !== apkUrl) return next()

    let stat
    try {
      stat = fs.statSync(apkSource)
    } catch {
      return next()
    }

    res.setHeader('Content-Type', 'application/vnd.android.package-archive')
    res.setHeader('Content-Length', stat.size)
    res.setHeader('Content-Disposition', 'attachment; filename="GreenRoute.apk"')
    res.setHeader('Cache-Control', 'no-store')

    if (req.method === 'HEAD') return res.end()
    fs.createReadStream(apkSource).pipe(res)
  }

  return {
    name: 'greentech-flutter-apk',
    configResolved(config) {
      outDir = path.resolve(config.root, config.build.outDir)
    },
    configureServer(server) {
      server.middlewares.use(serve)
    },
    configurePreviewServer(server) {
      server.middlewares.use(serve)
    },
    closeBundle() {
      if (!fs.existsSync(apkSource)) {
        this.warn(
          `No Flutter release APK at ${apkSource} — falling back to public/GreenRoute.apk. Run "flutter build apk --split-per-abi" to refresh it.`,
        )
        return
      }
      fs.copyFileSync(apkSource, path.join(outDir, 'GreenRoute.apk'))
    },
  }
}

export default defineConfig({
  plugins: [
    react(),
    babel({ presets: [reactCompilerPreset()] }),
    tailwindcss(),
    flutterApk(),
  ],
  resolve: {
    alias: {
      '@': path.resolve(rootDir, './src'),
    },
  },
  server: { port: 3000 },
  preview: { port: 3000 },
})
