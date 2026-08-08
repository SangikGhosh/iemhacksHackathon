import { motion } from 'motion/react'
import { Layers, Navigation, Waypoints } from 'lucide-react'

import { municipalities, localities } from '@/lib/site'
import { GhostWord, Mono, SectionHeading } from './ui/section'
import { Marquee } from './ui/marquee'

/* Stylised, not geographic — the point is the river, not the coastline. */
const stops = [
  { x: 210, y: 96, label: 'CP-HMC-012' },
  { x: 286, y: 158, label: 'CP-HMC-029' },
  { x: 172, y: 214, label: 'CP-HMC-026' },
  { x: 296, y: 268, label: 'CP-HMC-041' },
  { x: 190, y: 320, label: 'CP-HMC-055' },
]

export function NetworkSection() {
  return (
    <section id="network" className="relative overflow-hidden px-5 py-24 sm:px-6 md:py-32">
      <GhostWord>NETWORK</GhostWord>

      <div className="relative z-10 mx-auto max-w-7xl">
        <SectionHeading
          eyebrow="Maps & routing"
          title="The nearest point on a map is not the nearest to drive to"
          subtitle="Across the Hooghly the road runs up to 1.7× the straight line. Ranking on distance alone sends people to the wrong bank of the river, so ranking happens on real driving duration instead."
        />

        <div className="mb-20 grid items-center gap-10 lg:grid-cols-2 lg:gap-16">
          {/* Map */}
          <div className="relative overflow-hidden rounded-3xl border border-border bg-gradient-to-br from-neutral-50 to-neutral-100 p-4 sm:p-6">
            <svg viewBox="0 0 460 400" className="h-auto w-full" role="img" aria-label="Stylised route from a municipal depot through five collection points and back">
              <defs>
                <linearGradient id="river" x1="0" y1="0" x2="1" y2="1">
                  <stop offset="0%" stopColor="oklch(0.72 0.09 240)" stopOpacity="0.35" />
                  <stop offset="100%" stopColor="oklch(0.55 0.13 250)" stopOpacity="0.5" />
                </linearGradient>
                <linearGradient id="routeLine" x1="0" y1="0" x2="1" y2="1">
                  <stop offset="0%" stopColor="var(--brand-500)" />
                  <stop offset="100%" stopColor="var(--depot-500)" />
                </linearGradient>
              </defs>

              {/* Grid */}
              <g opacity="0.5">
                {Array.from({ length: 10 }).map((_, i) => (
                  <line key={`h${i}`} x1="0" y1={i * 44} x2="460" y2={i * 44} stroke="oklch(0.9 0 0)" strokeWidth="1" />
                ))}
                {Array.from({ length: 11 }).map((_, i) => (
                  <line key={`v${i}`} x1={i * 46} y1="0" x2={i * 46} y2="400" stroke="oklch(0.9 0 0)" strokeWidth="1" />
                ))}
              </g>

              {/* The Hooghly */}
              <path
                d="M96,0 C118,90 70,150 104,224 C136,292 92,330 118,400 L188,400 C160,330 202,292 172,224 C140,150 186,92 166,0 Z"
                fill="url(#river)"
              />
              <text x="104" y="382" className="fill-neutral-500" style={{ fontSize: 11, fontFamily: 'var(--font-mono)' }}>
                Hooghly
              </text>

              {/* Route */}
              <motion.path
                d="M56,60 L210,96 L286,158 L172,214 L296,268 L190,320 L56,60"
                fill="none"
                stroke="url(#routeLine)"
                strokeWidth="2.5"
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeDasharray="600"
                initial={{ strokeDashoffset: 600 }}
                whileInView={{ strokeDashoffset: 0 }}
                transition={{ duration: 2.2, ease: 'easeInOut' }}
                viewport={{ once: true }}
              />

              {/* Straight-line comparison */}
              <line x1="286" y1="158" x2="172" y2="214" stroke="oklch(0.6 0.18 25)" strokeWidth="1.5" strokeDasharray="4 4" />
              <text x="196" y="180" className="fill-red-600" style={{ fontSize: 10, fontFamily: 'var(--font-mono)' }}>
                1.32 km
              </text>
              <text x="196" y="194" className="fill-neutral-500" style={{ fontSize: 10, fontFamily: 'var(--font-mono)' }}>
                road 2.25 km
              </text>

              {/* Depot */}
              <g>
                <circle cx="56" cy="60" r="16" fill="var(--depot-600)" opacity="0.15" />
                <circle cx="56" cy="60" r="8" fill="var(--depot-600)" />
                <text x="56" y="38" textAnchor="middle" className="fill-neutral-700" style={{ fontSize: 11, fontWeight: 600 }}>
                  Depot
                </text>
              </g>

              {/* Stops */}
              {stops.map((stop, i) => (
                <motion.g
                  key={stop.label}
                  initial={{ opacity: 0, scale: 0 }}
                  whileInView={{ opacity: 1, scale: 1 }}
                  transition={{ delay: 0.4 + i * 0.22, duration: 0.35 }}
                  viewport={{ once: true }}
                  style={{ transformOrigin: `${stop.x}px ${stop.y}px` }}
                >
                  <circle cx={stop.x} cy={stop.y} r="12" fill="var(--brand-500)" opacity="0.16" />
                  <circle cx={stop.x} cy={stop.y} r="5.5" fill="var(--brand-600)" />
                  <text
                    x={stop.x + 12}
                    y={stop.y + 4}
                    className="fill-neutral-500"
                    style={{ fontSize: 9.5, fontFamily: 'var(--font-mono)' }}
                  >
                    {stop.label}
                  </text>
                </motion.g>
              ))}
            </svg>

            <div className="mt-2 flex flex-wrap items-center justify-between gap-3 border-t border-border pt-4 text-xs text-muted-foreground">
              <span>6 requests → 2 stops aggregated</span>
              <span className="font-mono">33.09 km · 128 min · 1.1 s</span>
            </div>
          </div>

          {/* Explanation */}
          <div className="space-y-8">
            {[
              {
                icon: Navigation,
                title: 'Two-stage nearest search',
                body: 'A haversine bounding box narrows candidates inside Postgres with no API call at all, then the top five go to the Mapbox Matrix API and are ranked by real driving duration. If Mapbox is unreachable the endpoint falls back to straight-line order and returns roadDistanceKm as null rather than failing.',
              },
              {
                icon: Layers,
                title: 'Stop aggregation is the efficiency story',
                body: 'Drop-offs that share a collection point collapse into a single stop — six requests across two points is a two-stop route, not six. That ratio between totalRequests and totalStops is the number worth putting on a slide.',
              },
              {
                icon: Waypoints,
                title: 'Why not the Mapbox Optimization API',
                body: 'Optimization v1 accepts twelve coordinates and supports neither vehicle capacity nor multiple vehicles, and v2 with those features is invite-only beta. So Matrix supplies real road durations and the ordering is solved locally with nearest-neighbour plus 2-opt.',
              },
            ].map((item, i) => (
              <motion.div
                key={item.title}
                initial={{ opacity: 0, x: 16 }}
                whileInView={{ opacity: 1, x: 0 }}
                transition={{ duration: 0.5, delay: i * 0.12 }}
                viewport={{ once: true, margin: '-60px' }}
                className="flex gap-4"
              >
                <span className="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl border border-border bg-gradient-to-br from-brand-50 to-white">
                  <item.icon className="h-5 w-5 text-brand-700" strokeWidth={1.6} />
                </span>
                <div>
                  <h3 className="mb-2 font-medium text-balance">{item.title}</h3>
                  <p className="text-sm leading-relaxed text-muted-foreground text-pretty">
                    {item.body}
                  </p>
                </div>
              </motion.div>
            ))}
          </div>
        </div>

        {/* Municipalities */}
        <div className="mb-10 overflow-hidden rounded-3xl border border-border bg-card">
          <div className="border-b border-border px-6 py-5 sm:px-8">
            <h3 className="text-lg font-medium">The seeded register</h3>
            <p className="mt-1 text-sm text-muted-foreground text-pretty">
              155 points and 4 depots, loaded on first boot from CSV. Seeding is idempotent —
              restarting imports nothing, appending rows imports only the new ones.
            </p>
          </div>

          <div className="overflow-x-auto">
            <table className="w-full min-w-[540px] text-sm">
              <thead>
                <tr className="border-b border-border text-left text-xs uppercase tracking-wider text-muted-foreground">
                  <th className="px-6 py-3 font-medium sm:px-8">Code</th>
                  <th className="px-6 py-3 font-medium">Municipality</th>
                  <th className="px-6 py-3 font-medium">District</th>
                  <th className="px-6 py-3 text-right font-medium sm:px-8">Points</th>
                </tr>
              </thead>
              <tbody>
                {municipalities.map((m) => (
                  <tr key={m.code} className="border-b border-border last:border-0 transition-colors hover:bg-muted/50">
                    <td className="px-6 py-4 sm:px-8">
                      <Mono>{m.code}</Mono>
                    </td>
                    <td className="px-6 py-4 font-medium">{m.name}</td>
                    <td className="px-6 py-4 text-muted-foreground">{m.district}</td>
                    <td className="px-6 py-4 text-right tabular-nums sm:px-8">
                      {m.depotOnly ? (
                        <span className="text-muted-foreground">depot only</span>
                      ) : (
                        m.points
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>

        <div className="relative">
          <div className="pointer-events-none absolute inset-y-0 left-0 z-10 w-24 bg-gradient-to-r from-background to-transparent" />
          <div className="pointer-events-none absolute inset-y-0 right-0 z-10 w-24 bg-gradient-to-l from-background to-transparent" />
          <Marquee pauseOnHover className="[--duration:32s]">
            {localities.map((locality) => (
              <span
                key={locality}
                className="rounded-full border border-border bg-card px-4 py-2 text-sm text-muted-foreground"
              >
                {locality}
              </span>
            ))}
          </Marquee>
        </div>

        <p className="mx-auto mt-6 max-w-3xl text-center text-xs leading-relaxed text-muted-foreground text-pretty">
          Points were generated by geocoding real localities and validating them against district
          bounds. One thing learned the hard way: geocoding administrative names is unreliable —
          "Howrah Municipal Corporation" resolves to a town in Maharashtra. Locality names resolve
          correctly.
        </p>
      </div>
    </section>
  )
}
