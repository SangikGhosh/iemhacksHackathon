import { motion } from 'motion/react'
import { ArrowDownRight, ArrowUpRight, Minus } from 'lucide-react'

import { cn } from '@/lib/utils'
import { NumberTicker } from '@/components/ui/number-ticker'

/* -------------------------------------------------------------------------- */
/* Card                                                                        */
/* -------------------------------------------------------------------------- */

export function Card({ className, children, ...props }) {
  return (
    <div
      className={cn(
        /* min-w-0 is load-bearing: a grid item defaults to min-width:auto, so
           without it the track grows to fit a wide table's min-content and the
           inner overflow-x-auto never gets a chance to scroll — the whole page
           scrolls sideways instead. */
        'min-w-0 rounded-2xl border border-border bg-white',
        className,
      )}
      {...props}
    >
      {children}
    </div>
  )
}

export function CardHeader({ title, subtitle, action, className }) {
  return (
    <div className={cn('flex items-start justify-between gap-4 border-b border-border px-5 py-4', className)}>
      <div className="min-w-0">
        <h3 className="text-sm font-semibold">{title}</h3>
        {subtitle && <p className="mt-0.5 text-xs text-muted-foreground text-pretty">{subtitle}</p>}
      </div>
      {action}
    </div>
  )
}

/* -------------------------------------------------------------------------- */
/* Stat tile                                                                   */
/* -------------------------------------------------------------------------- */

export function StatCard({
  label, value, suffix = '', prefix = '', delta, deltaLabel, icon: Icon,
  decimals = 0, index = 0, sparkline,
}) {
  const direction = delta > 0 ? 'up' : delta < 0 ? 'down' : 'flat'
  const DeltaIcon = direction === 'up' ? ArrowUpRight : direction === 'down' ? ArrowDownRight : Minus

  return (
    <motion.div
      initial={{ opacity: 0, y: 14 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.4, delay: index * 0.06 }}
      className="h-full"
    >
      <Card className="flex h-full flex-col p-5">
        <div className="mb-3 flex items-start justify-between gap-3">
          <p className="text-xs font-medium uppercase tracking-wider text-muted-foreground text-pretty">
            {label}
          </p>
          {Icon && (
            <span className="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg bg-muted">
              <Icon className="h-4 w-4 text-muted-foreground" strokeWidth={1.7} />
            </span>
          )}
        </div>

        <p className="text-3xl font-light leading-none tracking-tight">
          {prefix}
          <NumberTicker value={value} decimalPlaces={decimals} delay={index * 0.06} />
          {suffix}
        </p>

        {delta != null && (
          <div className="mt-3 flex flex-wrap items-center gap-x-1.5 gap-y-1">
            <span
              className={cn(
                'inline-flex items-center gap-0.5 rounded-full px-1.5 py-0.5 text-[11px] font-medium tabular-nums',
                direction === 'up' && 'bg-emerald-50 text-emerald-700',
                direction === 'down' && 'bg-red-50 text-red-700',
                direction === 'flat' && 'bg-neutral-100 text-neutral-600',
              )}
            >
              <DeltaIcon className="h-3 w-3" />
              {Math.abs(delta)}%
            </span>
            {deltaLabel && <span className="text-[11px] text-muted-foreground">{deltaLabel}</span>}
          </div>
        )}

        {/* In flow, below the delta — overlaying it ran the trend line straight
            through the percentage text. */}
        {sparkline && <div className="mt-auto pt-4">{sparkline}</div>}
      </Card>
    </motion.div>
  )
}

/* -------------------------------------------------------------------------- */
/* Status pill                                                                 */
/* -------------------------------------------------------------------------- */

const statusTones = {
  REQUESTED: 'bg-amber-50 text-amber-700 ring-amber-200',
  ACCEPTED: 'bg-blue-50 text-blue-700 ring-blue-200',
  COMPLETED: 'bg-emerald-50 text-emerald-700 ring-emerald-200',
  CANCELLED: 'bg-neutral-100 text-neutral-600 ring-neutral-200',
  HEALTHY: 'bg-emerald-50 text-emerald-700 ring-emerald-200',
  DEGRADED: 'bg-amber-50 text-amber-700 ring-amber-200',
  DOWN: 'bg-red-50 text-red-700 ring-red-200',
  ACTIVE: 'bg-emerald-50 text-emerald-700 ring-emerald-200',
  IDLE: 'bg-neutral-100 text-neutral-600 ring-neutral-200',
  FULL: 'bg-red-50 text-red-700 ring-red-200',
  OK: 'bg-emerald-50 text-emerald-700 ring-emerald-200',
}

export function StatusPill({ status, className }) {
  return (
    <span
      className={cn(
        'inline-flex items-center rounded-full px-2 py-0.5 font-mono text-[10px] font-medium uppercase tracking-wide ring-1 ring-inset',
        statusTones[status] ?? 'bg-neutral-100 text-neutral-600 ring-neutral-200',
        className,
      )}
    >
      {status}
    </span>
  )
}

/* -------------------------------------------------------------------------- */
/* Table                                                                       */
/* -------------------------------------------------------------------------- */

export function DataTable({ columns, rows, empty = 'Nothing to show', minWidth = 720 }) {
  if (!rows.length) {
    return <p className="px-5 py-10 text-center text-sm text-muted-foreground">{empty}</p>
  }

  return (
    <div className="overflow-x-auto">
      <table className="w-full text-sm" style={{ minWidth }}>
        <thead>
          <tr className="border-b border-border">
            {columns.map((col) => (
              <th
                key={col.key}
                scope="col"
                className={cn(
                  'whitespace-nowrap px-5 py-3 text-left text-[11px] font-medium uppercase tracking-wider text-muted-foreground',
                  col.align === 'right' && 'text-right',
                )}
              >
                {col.label}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {rows.map((row, i) => (
            <tr
              key={row.id ?? i}
              className="border-b border-border transition-colors last:border-0 hover:bg-muted/50"
            >
              {columns.map((col) => (
                <td
                  key={col.key}
                  className={cn(
                    'px-5 py-3.5 align-middle',
                    col.align === 'right' && 'text-right tabular-nums',
                    col.mono && 'font-mono text-xs',
                  )}
                >
                  {col.render ? col.render(row) : row[col.key]}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}

/* -------------------------------------------------------------------------- */
/* Progress bar                                                                */
/* -------------------------------------------------------------------------- */

export function ProgressBar({ value, max = 100, color = 'var(--brand-500)', className }) {
  const pct = Math.min(100, Math.max(0, (value / max) * 100))
  return (
    <div className={cn('h-1.5 w-full overflow-hidden rounded-full bg-neutral-200', className)}>
      <motion.div
        initial={{ width: 0 }}
        animate={{ width: `${pct}%` }}
        transition={{ duration: 0.8, ease: 'easeOut' }}
        className="h-full rounded-full"
        style={{ backgroundColor: color }}
      />
    </div>
  )
}

/* -------------------------------------------------------------------------- */
/* Section header inside a console page                                        */
/* -------------------------------------------------------------------------- */

export function PageHeading({ title, subtitle, action }) {
  return (
    <div className="mb-6 flex flex-wrap items-end justify-between gap-4">
      <div>
        <h2 className="text-xl font-semibold tracking-tight sm:text-2xl">{title}</h2>
        {subtitle && (
          <p className="mt-1 max-w-2xl text-sm text-muted-foreground text-pretty">{subtitle}</p>
        )}
      </div>
      {action}
    </div>
  )
}
