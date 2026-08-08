import { useEffect } from 'react'
import { useLocation } from 'react-router-dom'

/**
 * Route changes should land at the top of the new page. Without this, moving
 * from the footer of the landing page into an admin console drops you halfway
 * down the dashboard.
 */
export default function ScrollToTop() {
  const { pathname, hash } = useLocation()

  useEffect(() => {
    if (hash) return
    window.scrollTo({ top: 0, left: 0, behavior: 'instant' })
  }, [pathname, hash])

  return null
}
