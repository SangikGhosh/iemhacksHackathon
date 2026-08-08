import { ArrowRight, ArrowUpRight } from 'lucide-react'
import { Link } from 'react-router-dom'

import { cn } from '@/lib/utils'

/**
 * The signature pill button: a wipe fill on hover and an arrow that swaps to a
 * diagonal. Jotterly repeats this markup in six places — here it is once.
 *
 * `variant="solid"` is the filled call to action, `"outline"` the wipe-on-hover
 * secondary. Renders as a react-router Link for internal paths and an anchor
 * for hashes and external URLs.
 */
export function PillButton({
  href = '#',
  children,
  variant = 'outline',
  className,
  icon: Icon,
  external = false,
  ...props
}) {
  const isInternalRoute = href.startsWith('/') && !external
  const Tag = isInternalRoute ? Link : 'a'
  const linkProps = isInternalRoute
    ? { to: href }
    : { href, ...(external ? { target: '_blank', rel: 'noreferrer noopener' } : {}) }

  const solid = variant === 'solid'

  return (
    <Tag
      {...linkProps}
      {...props}
      className={cn(
        'group relative inline-flex shrink-0 items-center overflow-hidden rounded-full py-1.5 pl-6 pr-1.5 transition-all duration-300',
        solid
          ? 'bg-foreground text-background hover:bg-foreground/90'
          : 'border border-border text-foreground',
        className,
      )}
    >
      {!solid && (
        <span className="absolute inset-0 origin-right scale-x-0 rounded-full bg-foreground transition-transform duration-300 group-hover:scale-x-100" />
      )}

      <span
        className={cn(
          'relative z-10 flex items-center gap-2 pr-4 text-sm whitespace-nowrap transition-colors duration-300',
          !solid && 'group-hover:text-background',
        )}
      >
        {Icon && <Icon className="h-4 w-4" />}
        {children}
      </span>

      <span
        className={cn(
          'relative z-10 flex h-9 w-9 shrink-0 items-center justify-center rounded-full',
          solid && 'bg-background',
        )}
      >
        <ArrowRight
          className={cn(
            'absolute h-4 w-4 transition-opacity duration-300 group-hover:opacity-0',
            solid ? 'text-foreground' : 'text-foreground',
          )}
        />
        <ArrowUpRight
          className={cn(
            'h-4 w-4 opacity-0 transition-all duration-300 group-hover:opacity-100',
            solid ? 'text-foreground' : 'text-foreground group-hover:text-background',
          )}
        />
      </span>
    </Tag>
  )
}
