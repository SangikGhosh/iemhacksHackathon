import { useEffect, useMemo, useRef, useState } from 'react'
import mapboxgl from 'mapbox-gl'
import 'mapbox-gl/dist/mapbox-gl.css'
import { MapPin, Warehouse } from 'lucide-react'

const TOKEN = import.meta.env.VITE_MAPBOX_TOKEN

const BIN_COLOUR = {
  MRF: '#1c64d7',
  BIN_CLUSTER: '#00863b',
  SCRAP_YARD: '#b45309',
  COMPOST_HUB: '#0f766e',
}

const DEFAULT_COLOUR = '#525252'

function bounds(points) {
  const box = new mapboxgl.LngLatBounds()
  points.forEach((p) => box.extend([p.lon, p.lat]))
  return box
}

/**
 * Collection points on a Mapbox map.
 *
 * Markers are plain DOM elements rather than a GeoJSON layer: at this scale
 * (a few hundred points) the difference is not measurable, and it keeps the
 * popup and colour logic in one readable place.
 */
export function PointsMap({ points, depots = [], height = 460, onSelect }) {
  const container = useRef(null)
  const map = useRef(null)
  const markers = useRef([])
  const [ready, setReady] = useState(false)
  const [failed, setFailed] = useState(null)

  const plotted = useMemo(
    () => points.filter((p) => Number.isFinite(p.lat) && Number.isFinite(p.lon)),
    [points],
  )

  useEffect(() => {
    if (!TOKEN || map.current || !container.current) return

    mapboxgl.accessToken = TOKEN

    try {
      map.current = new mapboxgl.Map({
        container: container.current,
        style: 'mapbox://styles/mapbox/light-v11',
        center: [88.31, 22.59],
        zoom: 10,
        attributionControl: true,
      })

      map.current.addControl(new mapboxgl.NavigationControl({ showCompass: false }), 'top-right')
      map.current.addControl(new mapboxgl.FullscreenControl(), 'top-right')
      map.current.on('load', () => setReady(true))
      map.current.on('error', (e) => setFailed(e?.error?.message || 'Map failed to load'))
    } catch (e) {
      // Deferred: setting state synchronously inside an effect cascades renders.
      queueMicrotask(() => setFailed(e.message))
    }

    return () => {
      map.current?.remove()
      map.current = null
    }
  }, [])

  useEffect(() => {
    if (!ready || !map.current) return

    markers.current.forEach((m) => m.remove())
    markers.current = []

    depots.forEach((d) => {
      const el = document.createElement('div')
      el.style.cssText =
        'width:22px;height:22px;border-radius:6px;background:#111827;border:2px solid #fff;' +
        'box-shadow:0 1px 4px rgba(0,0,0,.4);cursor:pointer'
      el.title = `${d.name} (depot)`

      const marker = new mapboxgl.Marker({ element: el })
        .setLngLat([d.lon, d.lat])
        .setPopup(
          new mapboxgl.Popup({ offset: 16 }).setHTML(
            `<strong>${d.name}</strong><br/><span style="color:#666">Depot · ${d.municipality}</span>`,
          ),
        )
        .addTo(map.current)

      markers.current.push(marker)
    })

    plotted.forEach((p) => {
      const el = document.createElement('div')
      const colour = p.active ? BIN_COLOUR[p.type] ?? DEFAULT_COLOUR : '#a3a3a3'
      el.style.cssText =
        `width:12px;height:12px;border-radius:50%;background:${colour};` +
        `border:2px solid #fff;box-shadow:0 1px 3px rgba(0,0,0,.35);cursor:pointer` +
        (p.active ? '' : ';opacity:.5')

      const marker = new mapboxgl.Marker({ element: el })
        .setLngLat([p.lon, p.lat])
        .setPopup(
          new mapboxgl.Popup({ offset: 12 }).setHTML(
            `<strong>${p.name}</strong><br/>` +
              `<span style="color:#666">${p.code} · ${p.type}</span><br/>` +
              `<span style="color:#666">${p.locality || ''} ${p.ward || ''}</span><br/>` +
              `<span style="color:#666">${p.municipality}</span>` +
              (p.active ? '' : '<br/><span style="color:#b91c1c">Retired</span>'),
          ),
        )
        .addTo(map.current)

      el.addEventListener('click', () => onSelect?.(p))
      markers.current.push(marker)
    })

    const all = [...plotted, ...depots]
    if (all.length === 1) {
      map.current.flyTo({ center: [all[0].lon, all[0].lat], zoom: 14 })
    } else if (all.length > 1) {
      map.current.fitBounds(bounds(all), { padding: 60, maxZoom: 14, duration: 600 })
    }
  }, [ready, plotted, depots, onSelect])

  if (!TOKEN) {
    return (
      <div
        className="grid place-items-center rounded-xl border border-dashed border-border bg-muted/40 text-center"
        style={{ height }}
      >
        <div className="max-w-xs px-6">
          <MapPin className="mx-auto mb-3 h-6 w-6 text-muted-foreground" />
          <p className="text-sm font-medium">Map token not set</p>
          <p className="mt-1 text-xs text-muted-foreground">
            Add <code className="font-mono">VITE_MAPBOX_TOKEN</code> to the web app&apos;s{' '}
            <code className="font-mono">.env</code> and restart the dev server.
          </p>
        </div>
      </div>
    )
  }

  return (
    <div className="relative">
      <div ref={container} style={{ height }} className="w-full overflow-hidden rounded-xl" />

      {failed && (
        <div className="absolute inset-0 grid place-items-center rounded-xl bg-white/85 px-6 text-center">
          <div>
            <p className="text-sm font-medium text-red-700">Map failed to load</p>
            <p className="mt-1 text-xs text-muted-foreground">{failed}</p>
          </div>
        </div>
      )}
    </div>
  )
}

export function MapLegend() {
  const items = [
    { label: 'Depot', colour: '#111827', square: true },
    { label: 'MRF', colour: BIN_COLOUR.MRF },
    { label: 'Bin cluster', colour: BIN_COLOUR.BIN_CLUSTER },
    { label: 'Scrap yard', colour: BIN_COLOUR.SCRAP_YARD },
    { label: 'Compost hub', colour: BIN_COLOUR.COMPOST_HUB },
    { label: 'Retired', colour: '#a3a3a3' },
  ]

  return (
    <div className="flex flex-wrap items-center gap-x-4 gap-y-2">
      {items.map((i) => (
        <span key={i.label} className="flex items-center gap-1.5 text-xs text-muted-foreground">
          <span
            className={i.square ? 'h-2.5 w-2.5 rounded-[3px]' : 'h-2.5 w-2.5 rounded-full'}
            style={{ backgroundColor: i.colour }}
          />
          {i.label}
        </span>
      ))}
      <span className="flex items-center gap-1.5 text-xs text-muted-foreground">
        <Warehouse className="h-3 w-3" />
        Routes start and end at the depot
      </span>
    </div>
  )
}
