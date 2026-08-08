import { motion } from 'motion/react'

import { pipeline, site } from '@/lib/site'
import { GhostWord, Mono } from './ui/section'

export function MissionSection() {
  return (
    <section id="how-it-works" className="relative overflow-hidden px-5 py-24 sm:px-6 md:py-32">
      <GhostWord position="top">MISSION</GhostWord>

      <div className="relative z-10 mx-auto max-w-7xl">
        {/* Mission panel */}
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          whileInView={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.7 }}
          viewport={{ once: true, margin: '-80px' }}
          className="grain relative mb-24 overflow-hidden rounded-3xl px-6 py-14 sm:px-10 lg:px-14 lg:py-20"
          style={{
            backgroundImage:
              'radial-gradient(120% 130% at 8% 6%, oklch(0.86 0.12 150) 0%, oklch(0.58 0.15 152) 30%, oklch(0.38 0.13 195) 62%, oklch(0.23 0.09 260) 100%)',
          }}
        >
          <img
            src="/logo-512.png"
            alt=""
            aria-hidden="true"
            className="pointer-events-none absolute -bottom-20 -right-12 w-[380px] max-w-[65%] select-none opacity-[0.09] mix-blend-luminosity"
          />

          <div className="relative z-10 max-w-3xl">
            <p className="mb-4 text-xs font-medium uppercase tracking-[0.2em] text-white/75">
              {site.hackathon.theme}
            </p>
            <h2 className="mb-8 text-balance text-4xl font-medium leading-[1.08] text-white md:text-5xl lg:text-[3.4rem]">
              Waste is only worthless once someone has mixed it.
            </h2>
            <div className="space-y-5 leading-relaxed text-white/85">
              <p>
                Segregation fails at the doorstep, not at the landfill. A household that cannot tell
                which bin a wrapper belongs in will not sort it, and once the wet and the dry are in
                the same bag the recyclable fraction is gone — along with the money it was worth.
              </p>
              <p>
                GreenTech puts the answer behind a camera. Photograph the waste and the app names
                the material, the bin colour, the price per kilo and the points it earns. Then it
                does the part a citizen cannot: finds the nearest collection point by real driving
                time, or puts the request in front of every collector at once.
              </p>
            </div>

            <div className="mt-10 flex flex-wrap gap-x-10 gap-y-5 border-t border-white/20 pt-8">
              {[
                { k: '155', v: 'Collection points seeded' },
                { k: '4', v: 'Municipal depots' },
                { k: '2', v: 'Districts covered' },
              ].map((item) => (
                <div key={item.v}>
                  <p className="text-3xl font-light text-white">{item.k}</p>
                  <p className="mt-0.5 text-xs uppercase tracking-wider text-white/65">{item.v}</p>
                </div>
              ))}
            </div>
          </div>
        </motion.div>

        {/* Pipeline */}
        <div className="mb-14 max-w-3xl">
          <p className="mb-4 text-xs font-medium uppercase tracking-[0.2em] text-brand-700">
            The flow
          </p>
          <h2 className="text-balance font-serif text-4xl font-normal leading-[1.1] md:text-5xl">
            How a scan becomes a collection
          </h2>
          <p className="mt-5 leading-relaxed text-muted-foreground text-pretty">
            Six steps, two services and one photograph. Every arrow below is a real endpoint, and
            every figure is measured rather than illustrative.
          </p>
        </div>

        <ol className="relative grid gap-x-8 gap-y-10 sm:grid-cols-2 lg:grid-cols-3">
          {pipeline.map((item, index) => (
            <motion.li
              key={item.step}
              initial={{ opacity: 0, y: 24 }}
              whileInView={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.5, delay: (index % 3) * 0.1 }}
              viewport={{ once: true, margin: '-60px' }}
              className="group relative"
            >
              <div className="mb-4 flex items-center gap-3">
                <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full border border-border bg-card font-mono text-xs font-medium transition-colors duration-300 group-hover:border-brand-400 group-hover:bg-brand-50 group-hover:text-brand-800">
                  {item.step}
                </span>
                <span className="h-px flex-1 bg-border" />
                <span className="shrink-0 rounded-full bg-muted px-2 py-0.5 font-mono text-[10px] uppercase tracking-wide text-muted-foreground">
                  {item.service}
                </span>
              </div>

              <h3 className="mb-2 text-lg font-medium text-balance">{item.title}</h3>
              <p className="mb-4 text-sm leading-relaxed text-muted-foreground text-pretty">
                {item.detail}
              </p>
              <Mono>{item.endpoint}</Mono>
            </motion.li>
          ))}
        </ol>
      </div>
    </section>
  )
}
