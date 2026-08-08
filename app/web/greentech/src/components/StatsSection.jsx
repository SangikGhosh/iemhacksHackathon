import { motion } from 'motion/react'

import { heroStats } from '@/lib/site'
import { NumberTicker } from './ui/number-ticker'

export function StatsSection() {
  return (
    <section className="border-b border-border px-5 py-20 sm:px-6 md:py-24">
      <div className="mx-auto max-w-5xl">
        <div className="grid grid-cols-2 gap-x-6 gap-y-12 md:grid-cols-4 md:gap-8">
          {heroStats.map((stat, index) => (
            <motion.div
              key={stat.label}
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.6, delay: index * 0.1 }}
              viewport={{ once: true, margin: '-60px' }}
              className="text-center"
            >
              <p className="mb-2 text-5xl font-light leading-none md:text-6xl">
                <NumberTicker value={stat.value} delay={index * 0.1} />
                {stat.suffix}
              </p>
              <p className="text-xs uppercase tracking-wider text-muted-foreground">{stat.label}</p>
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  )
}
