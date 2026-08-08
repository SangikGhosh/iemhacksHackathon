import { motion } from 'motion/react'

import { cn } from '@/lib/utils'

/** The oversized wordmark that sits behind a section. Decorative only. */
export function GhostWord({ children, className, position = 'center' }) {
  const placement = {
    center: 'inset-0 items-center',
    top: 'inset-x-0 top-0 items-start',
    bottom: 'inset-x-0 bottom-0 items-end',
  }[position]

  return (
    <div
      className={cn('pointer-events-none absolute flex justify-center overflow-hidden', placement, className)}
      aria-hidden="true"
    >
      <span className="word-ghost text-[22vw] sm:text-[18vw] lg:text-[14vw]">{children}</span>
    </div>
  )
}

/** Eyebrow + serif headline + supporting line, centred. */
export function SectionHeading({ eyebrow, title, subtitle, className, align = 'center' }) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      whileInView={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.6 }}
      viewport={{ once: true, margin: '-80px' }}
      className={cn(
        'mb-14',
        align === 'center' ? 'mx-auto max-w-3xl text-center' : 'max-w-3xl text-left',
        className,
      )}
    >
      {eyebrow && (
        <p className="mb-4 text-xs font-medium uppercase tracking-[0.2em] text-brand-700">{eyebrow}</p>
      )}
      <h2 className="font-serif text-4xl font-normal leading-[1.1] text-balance md:text-5xl">{title}</h2>
      {subtitle && (
        <p className="mt-5 leading-relaxed text-muted-foreground text-pretty">{subtitle}</p>
      )}
    </motion.div>
  )
}

/** Small monospace label used for endpoints, codes and statuses. */
export function Mono({ children, className }) {
  return (
    <code
      className={cn(
        'rounded-md border border-border bg-muted px-1.5 py-0.5 font-mono text-[0.72em] text-muted-foreground',
        className,
      )}
    >
      {children}
    </code>
  )
}
