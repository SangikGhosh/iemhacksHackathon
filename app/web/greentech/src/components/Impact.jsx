import { motion } from 'motion/react'
import { ArrowRight, Truck, MapPin } from 'lucide-react'

import { impactStats, collectionModes, pickupStates } from '@/lib/site'
import { cn } from '@/lib/utils'
import { GhostWord, SectionHeading, Mono } from './ui/section'
import { NumberTicker } from './ui/number-ticker'

const toneStyles = {
  amber: 'bg-amber-50 text-amber-800 border-amber-200',
  blue: 'bg-blue-50 text-blue-800 border-blue-200',
  green: 'bg-emerald-50 text-emerald-800 border-emerald-200',
  grey: 'bg-neutral-100 text-neutral-600 border-neutral-200',
}

export function ImpactSection() {
  return (
    <section id="impact" className="relative overflow-hidden bg-muted/40 px-5 py-24 sm:px-6 md:py-32">
      <GhostWord className="opacity-70">IMPACT</GhostWord>

      <div className="relative z-10 mx-auto max-w-7xl">
        <SectionHeading
          eyebrow="Measured, not projected"
          title="Verified against real services"
          subtitle="Real PostgreSQL, a real Resend account, a real Mapbox account and a real photograph of a full waste bin. These are the numbers that came back."
        />

        <div className="mb-24 grid grid-cols-2 gap-x-6 gap-y-12 lg:grid-cols-4 lg:gap-8">
          {impactStats.map((stat, index) => (
            <motion.div
              key={stat.label}
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.55, delay: index * 0.1 }}
              viewport={{ once: true, margin: '-60px' }}
              className="text-center"
            >
              <p className="mb-2 text-4xl font-light leading-none sm:text-5xl md:text-6xl">
                <NumberTicker
                  value={stat.value}
                  decimalPlaces={stat.decimals ?? 0}
                  delay={index * 0.1}
                />
                {stat.suffix}
              </p>
              <p className="mb-1.5 text-xs font-medium uppercase tracking-wider">{stat.label}</p>
              <p className="text-xs leading-snug text-muted-foreground text-pretty">
                {stat.caption}
              </p>
            </motion.div>
          ))}
        </div>

        {/* Collection modes */}
        <div className="mb-20 grid gap-6 md:grid-cols-2">
          {collectionModes.map((mode, i) => (
            <motion.div
              key={mode.mode}
              initial={{ opacity: 0, y: 24 }}
              whileInView={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.5, delay: i * 0.1 }}
              viewport={{ once: true, margin: '-60px' }}
              className={cn(
                'relative overflow-hidden rounded-3xl border p-8',
                mode.mode === 'DROP_OFF'
                  ? 'border-brand-200 bg-gradient-to-br from-brand-50 to-card'
                  : 'border-border bg-card',
              )}
            >
              <div className="mb-6 flex items-start justify-between gap-4">
                <span className="flex h-12 w-12 items-center justify-center rounded-2xl border border-border bg-card">
                  {mode.mode === 'DOORSTEP' ? (
                    <Truck className="h-5 w-5 text-brand-700" strokeWidth={1.6} />
                  ) : (
                    <MapPin className="h-5 w-5 text-brand-700" strokeWidth={1.6} />
                  )}
                </span>
                <Mono>{mode.mode}</Mono>
              </div>

              <div className="mb-3 flex items-baseline gap-2">
                <span className="text-5xl font-light leading-none">{mode.rate}</span>
                <span className="text-sm text-muted-foreground">{mode.unit}</span>
              </div>
              <h3 className="mb-2.5 text-lg font-medium">{mode.title}</h3>
              <p className="text-sm leading-relaxed text-muted-foreground text-pretty">
                {mode.description}
              </p>
            </motion.div>
          ))}
        </div>

        {/* Pickup lifecycle */}
        <div className="rounded-3xl border border-border bg-card p-6 sm:p-10">
          <div className="mb-8 max-w-2xl">
            <h3 className="mb-3 font-serif text-3xl font-normal text-balance">
              The pickup lifecycle
            </h3>
            <p className="leading-relaxed text-muted-foreground text-pretty">
              A citizen can cancel only while a pickup is still <Mono>REQUESTED</Mono>. Once a
              collector accepts they may already be travelling, so cancelling returns a 409 — and if
              the collector genuinely cannot make it they release it back to the feed instead.
            </p>
          </div>

          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
            {pickupStates.map((state, i) => (
              <motion.div
                key={state.status}
                initial={{ opacity: 0, y: 16 }}
                whileInView={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.45, delay: i * 0.09 }}
                viewport={{ once: true }}
                className="relative"
              >
                <div className="h-full rounded-2xl border border-border bg-background p-5">
                  <span
                    className={cn(
                      'mb-4 inline-block rounded-full border px-2.5 py-1 font-mono text-[10px] font-medium',
                      toneStyles[state.tone],
                    )}
                  >
                    {state.status}
                  </span>
                  <p className="mb-2 text-sm font-medium text-pretty">{state.meaning}</p>
                  <p className="text-xs leading-relaxed text-muted-foreground text-pretty">
                    {state.actor}
                  </p>
                </div>

                {i < pickupStates.length - 1 && (
                  <ArrowRight
                    className="absolute -right-3 top-1/2 hidden h-4 w-4 -translate-y-1/2 text-border lg:block"
                    aria-hidden="true"
                  />
                )}
              </motion.div>
            ))}
          </div>

          <p className="mt-8 border-t border-border pt-6 text-sm leading-relaxed text-muted-foreground text-pretty">
            Acceptance is one atomic <Mono>UPDATE … WHERE status = 'REQUESTED'</Mono>. The
            read-then-write version passed every sequential test and then returned 200 to all six
            collectors tapping at the same instant — five of whom would have driven to an address
            for waste that was already claimed.
          </p>
        </div>
      </div>
    </section>
  )
}
