import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'

import '@fontsource-variable/inter'
import '@fontsource-variable/playfair-display'
import '@fontsource-variable/geist-mono'

import Router from './Router.jsx'
import './index.css'

createRoot(document.getElementById('root')).render(
  <StrictMode>
    <Router />
  </StrictMode>,
)
