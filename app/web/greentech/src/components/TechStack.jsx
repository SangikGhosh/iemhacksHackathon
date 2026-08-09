import { motion } from 'motion/react'

import { stack, limitations } from '@/lib/site'
import { GhostWord, Mono, SectionHeading } from './ui/section'

export function TechStack() {
  return (
    <section id="tech" className="relative overflow-hidden px-5 py-24 sm:px-6 md:py-32">
      <GhostWord>STACK</GhostWord>

      <div className="relative z-10 mx-auto max-w-7xl">
        <SectionHeading
          eyebrow="Architecture"
          title="Two services, deliberately apart"
          subtitle="Detection is CPU-heavy and stateless; auth and history are transactional. Keeping them separate means the detection service can be restarted, scaled or swapped for a GPU box without touching user data."
        />

        {/* Architecture strip */}
        <div className="mb-16 overflow-hidden rounded-3xl border border-border bg-card">
          <div className="grid divide-y divide-border lg:grid-cols-3 lg:divide-x lg:divide-y-0">
            {[
              {
                title: 'Mobile and web',
                stack: 'Flutter · React',
                body: 'The Android app and both admin consoles are the only things a person ever touches. They talk to a single backend, always over an authenticated connection.',
              },
              {
                title: 'Application backend',
                stack: 'Spring Boot · Java 17',
                body: 'The system of record. It signs people in, passes the photo on for recognition, stores the result and credits the points — all as one operation that either finishes or does not.',
              },
              {
                title: 'Detection service',
                stack: 'FastAPI · YOLOv8',
                body: 'Does the image recognition and nothing else. No app talks to it directly, so it stays on a private network behind the backend.',
              },
            ].map((node, i) => (
              <motion.div
                key={node.title}
                initial={{ opacity: 0, y: 16 }}
                whileInView={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.45, delay: i * 0.1 }}
                viewport={{ once: true }}
                className="p-7"
              >
                <div className="mb-3 flex items-center justify-between gap-3">
                  <h3 className="text-base font-medium">{node.title}</h3>
                  <Mono>{node.stack}</Mono>
                </div>
                <p className="text-sm leading-relaxed text-muted-foreground text-pretty">
                  {node.body}
                </p>
              </motion.div>
            ))}
          </div>
        </div>

        {/* Stack grid */}
        <div className="mb-24 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {stack.map((item, i) => (
            <motion.div
              key={item.layer}
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.45, delay: (i % 3) * 0.08 }}
              viewport={{ once: true, margin: '-60px' }}
              className="group rounded-2xl border border-border bg-card p-6 transition-colors duration-300 hover:border-foreground/20"
            >
              <p className="mb-3 text-[10px] font-medium uppercase tracking-[0.18em] text-brand-700">
                {item.layer}
              </p>
              <h3 className="mb-2 text-lg font-medium">{item.name}</h3>
              <p className="mb-5 text-sm leading-relaxed text-muted-foreground text-pretty">
                {item.detail}
              </p>
              <div className="flex flex-wrap gap-1.5">
                {item.items.map((chip) => (
                  <span
                    key={chip}
                    className="rounded-full bg-muted px-2.5 py-1 font-mono text-[10px] text-muted-foreground"
                  >
                    {chip}
                  </span>
                ))}
              </div>
            </motion.div>
          ))}
        </div>

        {/* Limitations */}
        <div className="grid gap-10 lg:grid-cols-[minmax(0,0.85fr)_minmax(0,1.15fr)] lg:gap-16">
          <div>
            <p className="mb-4 text-xs font-medium uppercase tracking-[0.2em] text-brand-700">
              Honest limitations
            </p>
            <h3 className="mb-5 font-serif text-3xl font-normal leading-[1.1] text-balance md:text-4xl">
              What this does not do yet
            </h3>
            <p className="leading-relaxed text-muted-foreground text-pretty">
              Every one of these is a real constraint we would rather state plainly than have a
              judge find. The design concedes the limit instead of pretending a camera can weigh
              things.
            </p>
          </div>

          <div className="divide-y divide-border border-y border-border">
            {limitations.map((limit, i) => (
              <motion.div
                key={limit.title}
                initial={{ opacity: 0, y: 14 }}
                whileInView={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.4, delay: i * 0.06 }}
                viewport={{ once: true, margin: '-40px' }}
                className="py-5"
              >
                <h4 className="mb-1.5 font-medium text-balance">{limit.title}</h4>
                <p className="text-sm leading-relaxed text-muted-foreground text-pretty">
                  {limit.body}
                </p>
              </motion.div>
            ))}
          </div>
        </div>
      </div>
    </section>
  )
}
