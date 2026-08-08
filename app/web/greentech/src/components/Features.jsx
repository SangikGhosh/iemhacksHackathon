import { motion } from 'motion/react'
import {
  Boxes, Check, Coins, History, Route, ScanLine, ShieldCheck, Users, Zap,
} from 'lucide-react'

import { features, featureChecklist, bins } from '@/lib/site'
import { GhostWord, SectionHeading } from './ui/section'
import { CardSpotlight } from './ui/card-spotlight'

const icons = { ScanLine, ShieldCheck, Users, Zap, Route, Boxes, Coins, History }

export default function FeaturesSection() {
  return (
    <section id="features" className="relative overflow-hidden px-5 py-24 sm:px-6 md:py-32">
      <GhostWord>PLATFORM</GhostWord>

      <div className="relative z-10 mx-auto max-w-7xl">
        <SectionHeading
          eyebrow="What it does"
          title="Eight decisions worth defending"
          subtitle="Not a feature list — the specific engineering choices that make the difference between a demo and something a municipality could actually run."
        />

        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
          {features.map((feature, index) => {
            const Icon = icons[feature.icon]
            return (
              /* Eight cards across four columns — two full rows, no holes.
                 Spanning any card left a two-cell gap on the last row. */
              <motion.div
                key={feature.title}
                initial={{ opacity: 0, y: 24 }}
                whileInView={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.5, delay: (index % 4) * 0.07 }}
                viewport={{ once: true, margin: '-60px' }}
              >
                <CardSpotlight className="h-full p-6">
                  <div className="mb-5 flex items-start justify-between gap-3">
                    <span className="flex h-11 w-11 items-center justify-center rounded-xl border border-border bg-gradient-to-br from-brand-50 to-white">
                      <Icon className="h-5 w-5 text-brand-700" strokeWidth={1.6} />
                    </span>
                    <span className="rounded-full bg-muted px-2.5 py-1 font-mono text-[10px] uppercase tracking-wide text-muted-foreground">
                      {feature.tag}
                    </span>
                  </div>
                  <h3 className="mb-2.5 text-lg font-medium text-balance">{feature.title}</h3>
                  <p className="text-sm leading-relaxed text-muted-foreground text-pretty">
                    {feature.description}
                  </p>
                </CardSpotlight>
              </motion.div>
            )
          })}
        </div>

        {/* Bins + checklist */}
        <div className="mt-20 grid gap-12 lg:grid-cols-2 lg:gap-16">
          <div>
            <h3 className="mb-3 font-serif text-3xl font-normal text-balance">
              Sixteen materials, four bins
            </h3>
            <p className="mb-8 leading-relaxed text-muted-foreground text-pretty">
              Every detection resolves to a bin colour, and the bin is what the citizen actually
              acts on. Anything unmapped falls back to Mixed Waste in the grey bin rather than
              guessing.
            </p>

            <div className="space-y-3">
              {bins.map((bin, i) => (
                <motion.div
                  key={bin.key}
                  initial={{ opacity: 0, x: -12 }}
                  whileInView={{ opacity: 1, x: 0 }}
                  transition={{ duration: 0.45, delay: i * 0.08 }}
                  viewport={{ once: true }}
                  className="flex items-start gap-4 rounded-2xl border border-border bg-card p-4 transition-colors duration-300 hover:border-foreground/20"
                >
                  <span
                    className="mt-0.5 h-9 w-2.5 shrink-0 rounded-full"
                    style={{ backgroundColor: bin.color }}
                  />
                  <div className="min-w-0">
                    <div className="mb-1 flex flex-wrap items-center gap-2">
                      <span className="font-medium">{bin.name} bin</span>
                      <span className="rounded-full bg-muted px-2 py-0.5 font-mono text-[10px] uppercase tracking-wide text-muted-foreground">
                        {bin.stream}
                      </span>
                    </div>
                    <p className="text-sm leading-relaxed text-muted-foreground">
                      {bin.materials.join(' · ')}
                    </p>
                  </div>
                </motion.div>
              ))}
            </div>
          </div>

          <div>
            <h3 className="mb-3 font-serif text-3xl font-normal text-balance">
              Shipped and verified
            </h3>
            <p className="mb-8 leading-relaxed text-muted-foreground text-pretty">
              Twelve behaviours that already work end to end against real PostgreSQL, a real Mapbox
              account and a real photo of a full waste bin.
            </p>

            <div className="grid gap-x-6 gap-y-1 sm:grid-cols-2 lg:grid-cols-1 xl:grid-cols-2">
              {featureChecklist.map((item, index) => (
                <motion.div
                  key={item}
                  initial={{ opacity: 0, x: -10 }}
                  whileInView={{ opacity: 1, x: 0 }}
                  transition={{ duration: 0.35, delay: index * 0.05 }}
                  viewport={{ once: true }}
                  className="flex items-center gap-2.5 rounded-xl px-2 py-2 transition-colors duration-300 hover:bg-muted/70"
                >
                  <span className="flex h-5 w-5 shrink-0 items-center justify-center rounded-full bg-gradient-to-br from-brand-400 to-depot-500 shadow-sm">
                    <Check className="h-3 w-3 text-white" strokeWidth={3} />
                  </span>
                  <span className="text-sm text-pretty">{item}</span>
                </motion.div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}
