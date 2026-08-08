import { useState } from 'react'
import { motion, useMotionTemplate, useMotionValue } from 'motion/react'

import { cn } from '@/lib/utils'

/**
 * Aceternity — Card Spotlight.
 * A radial highlight that tracks the pointer. Pointer-only by design: on touch
 * there is no hover, and the card simply renders flat.
 */
export function CardSpotlight({ children, radius = 380, className, ...props }) {
  const mouseX = useMotionValue(0)
  const mouseY = useMotionValue(0)
  const [isHovering, setIsHovering] = useState(false)

  function handleMouseMove({ currentTarget, clientX, clientY }) {
    const { left, top } = currentTarget.getBoundingClientRect()
    mouseX.set(clientX - left)
    mouseY.set(clientY - top)
  }

  const background = useMotionTemplate`radial-gradient(${radius}px circle at ${mouseX}px ${mouseY}px, var(--brand-100), transparent 78%)`

  return (
    <div
      className={cn(
        'group/spotlight relative overflow-hidden rounded-2xl border border-border bg-card transition-colors duration-300 hover:border-foreground/20',
        className,
      )}
      onMouseMove={handleMouseMove}
      onMouseEnter={() => setIsHovering(true)}
      onMouseLeave={() => setIsHovering(false)}
      {...props}
    >
      <motion.div
        className="pointer-events-none absolute inset-0 opacity-0 transition-opacity duration-500"
        style={{ background, opacity: isHovering ? 0.55 : 0 }}
        aria-hidden="true"
      />
      <div className="relative z-10">{children}</div>
    </div>
  )
}
