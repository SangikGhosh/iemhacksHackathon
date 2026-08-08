import { useState } from 'react'
import { AnimatePresence, motion } from 'motion/react'
import { AlertTriangle, Camera, CheckCircle2, RotateCcw, XCircle } from 'lucide-react'

import { cn } from '@/lib/utils'
import { GhostWord, Mono, SectionHeading } from './ui/section'
import { BorderBeam } from './ui/border-beam'

/**
 * The four scenarios below are the measured results from the api-python README
 * ("Measured on real images"), not invented examples.
 */
const scenarios = [
  {
    id: 'bottles',
    label: 'Bin of bottles',
    status: 'MANUAL_PRICING_REQUIRED',
    offerStatus: 'PENDING_COLLECTOR_CONFIRMATION',
    eligible: true,
    objects: 13,
    material: 'PET Bottle ×13',
    bin: 'BLUE',
    weight: '0.39 kg',
    offer: '₹8.29 – 11.21',
    points: 65,
    carbon: '1.95 kg',
    confidence: 0.58,
    quality: 'MEDIUM',
    setBy: 'COLLECTOR',
    note: '13 items exceeds the 5-item manual-pricing threshold, and this is exactly where a flat 30 g unit weight is weakest — the photo contains one large jug among small bottles. Calling it ESTIMATED would be overclaiming.',
    /* Nine of the thirteen, sized like bottles in a bin rather than slabs. */
    boxes: [
      { t: 30, l: 8, w: 11, h: 25 }, { t: 26, l: 22, w: 10, h: 22 },
      { t: 33, l: 35, w: 12, h: 27 }, { t: 24, l: 50, w: 10, h: 21 },
      { t: 31, l: 63, w: 11, h: 24 }, { t: 28, l: 77, w: 12, h: 30 },
      { t: 60, l: 14, w: 13, h: 28 }, { t: 63, l: 33, w: 11, h: 24 },
      { t: 58, l: 55, w: 14, h: 32 },
    ],
    tone: 'ok',
  },
  {
    id: 'laptop',
    label: 'Single laptop',
    status: 'OK',
    offerStatus: 'ESTIMATED',
    eligible: true,
    objects: 1,
    material: 'E-Waste ×1',
    bin: 'RED',
    weight: '1.5 kg',
    offer: '₹153 – 207',
    points: 40,
    carbon: '3.20 kg',
    confidence: 0.86,
    quality: 'HIGH',
    setBy: 'SYSTEM',
    note: 'One material, one item, high confidence. This is the only shape of scan where the system stands behind its own number without deferring to the collector.',
    boxes: [{ t: 32, l: 22, w: 54, h: 40 }],
    tone: 'ok',
  },
  {
    id: 'banana',
    label: 'Banana only',
    status: 'OK',
    offerStatus: 'NO_RESALE_VALUE',
    eligible: true,
    objects: 1,
    material: 'Organic Waste ×1',
    bin: 'GREEN',
    weight: '0.15 kg',
    offer: '₹0',
    points: 2,
    carbon: '0.05 kg',
    confidence: 0.71,
    quality: 'HIGH',
    setBy: 'SYSTEM',
    note: 'Worth nothing and still worth points. Rewards are per item rather than per kilo precisely so that correct segregation of zero-value waste is still credited.',
    boxes: [{ t: 42, l: 34, w: 32, h: 24 }],
    tone: 'ok',
  },
  {
    id: 'human',
    label: 'Photo of a person',
    status: 'NO_WASTE_DETECTED',
    offerStatus: 'UNAVAILABLE',
    eligible: false,
    objects: 0,
    material: '—',
    bin: '—',
    weight: '—',
    offer: '₹0',
    points: 0,
    carbon: '—',
    confidence: 0.0,
    quality: 'NONE',
    setBy: 'COLLECTOR',
    note: 'Nothing mappable to waste. ignoredObjects is what makes the message specific — "the image shows person" rather than a blank failure — and the app reopens the camera.',
    boxes: [],
    tone: 'bad',
  },
]

const binColor = {
  BLUE: 'var(--bin-blue)',
  GREEN: 'var(--bin-green)',
  RED: 'var(--bin-red)',
  GREY: 'var(--bin-grey)',
  '—': 'var(--muted-foreground)',
}

export function ScannerDemo() {
  const [active, setActive] = useState(scenarios[0])

  return (
    <section id="scanner" className="relative overflow-hidden bg-muted/40 px-5 py-24 sm:px-6 md:py-32">
      <GhostWord position="top" className="opacity-70">
        DETECT
      </GhostWord>

      <div className="relative z-10 mx-auto max-w-7xl">
        <SectionHeading
          eyebrow="The scanner"
          title="Check one boolean, not a list of statuses"
          subtitle="A detection can succeed technically and still be unusable. All four of these return HTTP 200 — they are outcomes, not failures — and the client branches on a single eligible flag."
        />

        {/* Scenario picker */}
        <div className="mb-8 flex flex-wrap justify-center gap-2">
          {scenarios.map((s) => (
            <button
              key={s.id}
              onClick={() => setActive(s)}
              aria-pressed={active.id === s.id}
              className={cn(
                'rounded-full border px-4 py-2 text-sm transition-all duration-200',
                active.id === s.id
                  ? 'border-foreground bg-foreground text-background'
                  : 'border-border bg-card text-muted-foreground hover:border-foreground/30 hover:text-foreground',
              )}
            >
              {s.label}
            </button>
          ))}
        </div>

        <div className="grid gap-6 lg:grid-cols-[minmax(0,1fr)_minmax(0,1.15fr)]">
          {/* Viewfinder */}
          <div className="relative overflow-hidden rounded-3xl border border-border bg-neutral-900">
            <BorderBeam size={180} duration={12} />

            <div className="relative aspect-[4/3] w-full overflow-hidden">
              <div
                className="absolute inset-0"
                style={{
                  backgroundImage:
                    'radial-gradient(circle at 28% 32%, rgba(90,170,120,.42), transparent 46%), radial-gradient(circle at 74% 62%, rgba(70,110,200,.38), transparent 48%), linear-gradient(160deg,#2a2a2a,#141414)',
                }}
              />

              <AnimatePresence mode="wait">
                <motion.div
                  key={active.id}
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1 }}
                  exit={{ opacity: 0 }}
                  transition={{ duration: 0.25 }}
                  className="absolute inset-0"
                >
                  {active.boxes.map((box, i) => (
                    <motion.div
                      key={i}
                      initial={{ opacity: 0, scale: 0.92 }}
                      animate={{ opacity: 1, scale: 1 }}
                      transition={{ delay: 0.15 + i * 0.09, duration: 0.35 }}
                      className="absolute rounded-md border-2"
                      style={{
                        top: `${box.t}%`,
                        left: `${box.l}%`,
                        width: `${box.w}%`,
                        height: `${box.h}%`,
                        borderColor: binColor[active.bin],
                      }}
                    >
                      {/* The label is wider than the box on a phone, where it
                          wrapped and collided with its neighbours. */}
                      <span
                        className="absolute -top-[17px] left-0 hidden whitespace-nowrap rounded-sm px-1 font-mono text-[9px] font-medium text-neutral-900 sm:inline-block"
                        style={{ backgroundColor: binColor[active.bin] }}
                      >
                        obj-{String(i + 1).padStart(3, '0')}
                      </span>
                    </motion.div>
                  ))}

                  {!active.boxes.length && (
                    <div className="absolute inset-0 flex flex-col items-center justify-center gap-3 text-center">
                      <RotateCcw className="h-8 w-8 text-white/45" strokeWidth={1.25} />
                      <p className="max-w-[16rem] px-4 text-sm text-white/60">
                        No garbage detected. The image shows person.
                      </p>
                    </div>
                  )}
                </motion.div>
              </AnimatePresence>

              {/* Sweep */}
              <div
                className="pointer-events-none absolute inset-x-0 top-0 h-20 bg-gradient-to-b from-transparent via-white/12 to-transparent"
                style={{ animation: 'scan-sweep 3.6s ease-in-out infinite' }}
              />

              {/* Corner brackets */}
              {[
                'left-4 top-4 border-l-2 border-t-2',
                'right-4 top-4 border-r-2 border-t-2',
                'left-4 bottom-4 border-b-2 border-l-2',
                'right-4 bottom-4 border-b-2 border-r-2',
              ].map((pos) => (
                <span key={pos} className={cn('absolute h-6 w-6 border-white/35', pos)} />
              ))}

              <div className="absolute bottom-4 left-4 flex items-center gap-2 rounded-full bg-black/55 px-3 py-1.5 backdrop-blur-sm">
                <Camera className="h-3 w-3 text-white/80" />
                <span className="font-mono text-[10px] text-white/80">
                  1280 px · conf 0.30 · iou 0.50
                </span>
              </div>
            </div>
          </div>

          {/* Response */}
          <div className="rounded-3xl border border-border bg-card p-6 sm:p-8">
            <AnimatePresence mode="wait">
              <motion.div
                key={active.id}
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: -10 }}
                transition={{ duration: 0.22 }}
              >
                <div className="mb-6 flex flex-wrap items-center gap-3">
                  <span
                    className={cn(
                      'inline-flex items-center gap-1.5 rounded-full px-3 py-1 text-xs font-medium',
                      active.eligible
                        ? 'bg-brand-50 text-brand-800'
                        : 'bg-red-50 text-red-700',
                    )}
                  >
                    {active.eligible ? (
                      <CheckCircle2 className="h-3.5 w-3.5" />
                    ) : (
                      <XCircle className="h-3.5 w-3.5" />
                    )}
                    eligible: {String(active.eligible)}
                  </span>
                  <Mono>{active.status}</Mono>
                </div>

                <div className="mb-6 grid grid-cols-2 gap-x-6 gap-y-5 sm:grid-cols-3">
                  {[
                    { label: 'Objects', value: active.objects },
                    { label: 'Material', value: active.material },
                    { label: 'Weight', value: active.weight },
                    { label: 'Offer', value: active.offer },
                    { label: 'Points', value: `+${active.points}` },
                    { label: 'CO₂ saved', value: active.carbon },
                  ].map((row) => (
                    <div key={row.label}>
                      <p className="mb-1 text-[10px] uppercase tracking-wider text-muted-foreground">
                        {row.label}
                      </p>
                      <p className="text-sm font-medium">{row.value}</p>
                    </div>
                  ))}
                </div>

                <div className="mb-6 flex flex-wrap items-center gap-x-6 gap-y-3 border-y border-border py-4">
                  <div className="flex items-center gap-2">
                    <span
                      className="h-3 w-3 rounded-full"
                      style={{ backgroundColor: binColor[active.bin] }}
                    />
                    <span className="text-sm">
                      {active.bin === '—' ? 'No bin' : `${active.bin} bin`}
                    </span>
                  </div>
                  <div className="flex items-center gap-2">
                    <span className="text-xs text-muted-foreground">Confidence</span>
                    <div className="h-1.5 w-20 overflow-hidden rounded-full bg-muted">
                      <motion.div
                        initial={{ width: 0 }}
                        animate={{ width: `${active.confidence * 100}%` }}
                        transition={{ duration: 0.6, ease: 'easeOut' }}
                        className="h-full rounded-full bg-foreground"
                      />
                    </div>
                    <span className="font-mono text-xs">{active.confidence.toFixed(2)}</span>
                  </div>
                  <Mono>{active.quality}</Mono>
                </div>

                <div className="mb-5">
                  <p className="mb-2 flex items-center gap-1.5 text-[10px] uppercase tracking-wider text-muted-foreground">
                    offer.status
                  </p>
                  <div className="flex flex-wrap items-center gap-2">
                    <Mono className="text-[0.78em]">{active.offerStatus}</Mono>
                    <span className="text-xs text-muted-foreground">
                      finalPriceSetBy: <span className="text-foreground">{active.setBy}</span>
                    </span>
                  </div>
                </div>

                <div className="flex gap-3 rounded-2xl bg-muted/70 p-4">
                  <AlertTriangle className="mt-0.5 h-4 w-4 shrink-0 text-muted-foreground" />
                  <p className="text-sm leading-relaxed text-muted-foreground text-pretty">
                    {active.note}
                  </p>
                </div>
              </motion.div>
            </AnimatePresence>
          </div>
        </div>

        <p className="mx-auto mt-8 max-w-3xl text-center text-xs leading-relaxed text-muted-foreground">
          Ineligible scans are still stored, so history stays a complete record of what a user
          tried — they simply award nothing. Bounding boxes are returned in the original image's
          coordinate space, so a client can draw them straight onto the photo without rescaling.
        </p>
      </div>
    </section>
  )
}
