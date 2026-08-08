import { cn } from '@/lib/utils'

/**
 * MagicUI — Border Beam.
 * A light travelling the border of its parent via offset-path. The parent needs
 * `relative` and a matching radius.
 */
export function BorderBeam({
  className,
  size = 200,
  duration = 15,
  borderWidth = 1.5,
  colorFrom = 'var(--brand-400)',
  colorTo = 'var(--depot-500)',
  delay = 0,
}) {
  return (
    <div
      style={{
        '--size': size,
        '--duration': duration,
        '--border-width': borderWidth,
        '--color-from': colorFrom,
        '--color-to': colorTo,
        '--delay': `-${delay}s`,
      }}
      className={cn(
        'pointer-events-none absolute inset-0 rounded-[inherit]',
        '[border:calc(var(--border-width)*1px)_solid_transparent]',
        '![mask-clip:padding-box,border-box] ![mask-composite:intersect]',
        '[mask:linear-gradient(transparent,transparent),linear-gradient(white,white)]',
        'after:absolute after:aspect-square after:w-[calc(var(--size)*1px)]',
        'after:animate-[border-beam_calc(var(--duration)*1s)_infinite_linear]',
        'after:[animation-delay:var(--delay)]',
        'after:[background:linear-gradient(to_left,var(--color-from),var(--color-to),transparent)]',
        'after:[offset-anchor:90%_50%]',
        'after:[offset-path:rect(0_auto_auto_0_round_calc(var(--size)*1px))]',
        className,
      )}
    />
  )
}
