import { useEffect, useState } from 'react'

/**
 * Fetch-on-mount with a manual reload.
 *
 * `deps` is serialised into a single key so callers can pass plain values
 * without the hook needing a stable identity for the fetcher itself — the
 * fetcher is almost always an inline closure at the call site.
 *
 * On a dependency change the previous data stays on screen until the new
 * response lands, which keeps the search box from flashing empty.
 */
export function useApi(fetcher, deps = []) {
  const [state, setState] = useState({ data: null, error: null, loading: true })
  const [nonce, setNonce] = useState(0)

  const key = JSON.stringify(deps)

  useEffect(() => {
    let cancelled = false

    const load = async () => {
      try {
        const data = await fetcher()
        if (!cancelled) setState({ data, error: null, loading: false })
      } catch (error) {
        if (!cancelled) setState({ data: null, error, loading: false })
      }
    }

    load()

    return () => {
      cancelled = true
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [key, nonce])

  return { ...state, reload: () => setNonce((n) => n + 1) }
}
