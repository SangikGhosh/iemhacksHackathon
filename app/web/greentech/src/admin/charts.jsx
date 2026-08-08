import {
  Area, AreaChart, Bar, BarChart, CartesianGrid, Cell, Line, ResponsiveContainer,
  Tooltip, XAxis, YAxis,
} from 'recharts'

import { cn } from '@/lib/utils'
import { binVars, chartColors } from './chart-tokens'

const axisProps = {
  stroke: chartColors.axis,
  fontSize: 11,
  tickLine: false,
  axisLine: false,
}

/* -------------------------------------------------------------------------- */
/* Tooltip                                                                     */
/* -------------------------------------------------------------------------- */

function ChartTooltip({ active, payload, label, unit = '', labelFormatter }) {
  if (!active || !payload?.length) return null

  return (
    <div className="rounded-xl border border-border bg-white/95 px-3 py-2 shadow-lg backdrop-blur-sm">
      <p className="mb-1.5 text-[11px] font-medium text-muted-foreground">
        {labelFormatter ? labelFormatter(label) : label}
      </p>
      <div className="space-y-1">
        {payload.map((entry) => (
          <div key={entry.dataKey} className="flex items-center gap-2 text-xs">
            <span
              className="h-2 w-2 shrink-0 rounded-full"
              style={{ backgroundColor: entry.color ?? entry.payload?.fill }}
            />
            <span className="text-muted-foreground">{entry.name}</span>
            <span className="ml-auto font-medium tabular-nums">
              {typeof entry.value === 'number' ? entry.value.toLocaleString() : entry.value}
              {unit}
            </span>
          </div>
        ))}
      </div>
    </div>
  )
}

/* -------------------------------------------------------------------------- */
/* Legend — always present for two or more series                              */
/* -------------------------------------------------------------------------- */

export function ChartLegend({ items, className }) {
  return (
    <div className={cn('flex flex-wrap items-center gap-x-5 gap-y-2', className)}>
      {items.map((item) => (
        <span key={item.label} className="flex items-center gap-1.5 text-xs text-muted-foreground">
          <span className="h-2 w-2 rounded-full" style={{ backgroundColor: item.color }} />
          {item.label}
        </span>
      ))}
    </div>
  )
}

/* -------------------------------------------------------------------------- */
/* Trend — two series over time                                                */
/* -------------------------------------------------------------------------- */

export function TrendChart({ data, height = 260, series }) {
  return (
    <div className="min-w-0" style={{ width: '100%', height }}>
      <ResponsiveContainer>
        {/* No negative left margin here: combined with the axis width it
            clipped the leading digit, rendering 800 as 00. */}
        <AreaChart data={data} margin={{ top: 8, right: 8, bottom: 0, left: 0 }}>
          <defs>
            <linearGradient id="fillSeries1" x1="0" y1="0" x2="0" y2="1">
              <stop offset="0%" stopColor={chartColors.series1} stopOpacity={0.18} />
              <stop offset="100%" stopColor={chartColors.series1} stopOpacity={0} />
            </linearGradient>
          </defs>

          <CartesianGrid stroke={chartColors.grid} vertical={false} />
          <XAxis dataKey="day" {...axisProps} interval="preserveStartEnd" minTickGap={18} />
          <YAxis {...axisProps} width={48} allowDecimals={false} tickMargin={4} />
          <Tooltip
            content={<ChartTooltip />}
            cursor={{ stroke: chartColors.axis, strokeWidth: 1, strokeDasharray: '3 3' }}
          />

          <Area
            type="monotone"
            dataKey={series[0].key}
            name={series[0].label}
            stroke={chartColors.series1}
            strokeWidth={2}
            fill="url(#fillSeries1)"
            dot={false}
            activeDot={{ r: 4, strokeWidth: 2, stroke: '#fff' }}
          />
          <Line
            type="monotone"
            dataKey={series[1].key}
            name={series[1].label}
            stroke={chartColors.series2}
            strokeWidth={2}
            dot={false}
            activeDot={{ r: 4, strokeWidth: 2, stroke: '#fff' }}
          />
        </AreaChart>
      </ResponsiveContainer>
    </div>
  )
}

/* -------------------------------------------------------------------------- */
/* Magnitude — single hue, sequential                                          */
/* -------------------------------------------------------------------------- */

export function MagnitudeBars({ data, dataKey = 'value', labelKey = 'name', height = 260, unit = '' }) {
  const max = Math.max(...data.map((d) => d[dataKey]))

  return (
    <div className="min-w-0" style={{ width: '100%', height }}>
      <ResponsiveContainer>
        <BarChart data={data} layout="vertical" margin={{ top: 4, right: 16, bottom: 4, left: 4 }}>
          <CartesianGrid stroke={chartColors.grid} horizontal={false} />
          <XAxis type="number" {...axisProps} hide />
          <YAxis
            type="category"
            dataKey={labelKey}
            {...axisProps}
            width={104}
            tick={{ fontSize: 11, fill: chartColors.axis }}
          />
          <Tooltip content={<ChartTooltip unit={unit} />} cursor={{ fill: 'oklch(0.96 0 0)' }} />
          <Bar dataKey={dataKey} radius={[0, 4, 4, 0]} barSize={14}>
            {data.map((entry, i) => (
              /* More is darker — opacity steps the single hue by rank. */
              <Cell
                key={i}
                fill={chartColors.sequential}
                fillOpacity={0.35 + 0.65 * (entry[dataKey] / max)}
              />
            ))}
          </Bar>
        </BarChart>
      </ResponsiveContainer>
    </div>
  )
}

/* -------------------------------------------------------------------------- */
/* Bin breakdown — colour is decorative here, the label carries the meaning     */
/* -------------------------------------------------------------------------- */

export function BinBreakdown({ data, unit = 'kg' }) {
  const total = data.reduce((sum, d) => sum + d.value, 0)

  return (
    <div className="space-y-4">
      {data.map((row, i) => {
        const pct = total ? (row.value / total) * 100 : 0
        return (
          <div key={row.bin}>
            <div className="mb-1.5 flex items-baseline justify-between gap-3">
              <span className="flex items-center gap-2 text-sm">
                <span
                  className="h-2.5 w-2.5 shrink-0 rounded-full"
                  style={{ backgroundColor: binVars[row.bin] }}
                />
                {/* The bin name is always written out — never colour alone. */}
                <span className="font-medium">{row.bin}</span>
                <span className="text-xs text-muted-foreground">{row.stream}</span>
              </span>
              <span className="shrink-0 text-sm tabular-nums">
                {row.value.toLocaleString()} {unit}
                <span className="ml-1.5 text-xs text-muted-foreground">{pct.toFixed(0)}%</span>
              </span>
            </div>
            <div className="h-2 w-full overflow-hidden rounded-full bg-neutral-200">
              <div
                className="h-full rounded-full transition-[width] duration-700 ease-out"
                style={{
                  width: `${pct}%`,
                  backgroundColor: binVars[row.bin],
                  transitionDelay: `${i * 90}ms`,
                }}
              />
            </div>
          </div>
        )
      })}
    </div>
  )
}

/* -------------------------------------------------------------------------- */
/* Sparkline for stat tiles                                                    */
/* -------------------------------------------------------------------------- */

export function Sparkline({ data, color = chartColors.series1, height = 36 }) {
  return (
    <div className="min-w-0" style={{ width: '100%', height }}>
      <ResponsiveContainer>
        <AreaChart data={data} margin={{ top: 2, right: 0, bottom: 0, left: 0 }}>
          <defs>
            <linearGradient id={`spark-${color.replace('#', '')}`} x1="0" y1="0" x2="0" y2="1">
              <stop offset="0%" stopColor={color} stopOpacity={0.22} />
              <stop offset="100%" stopColor={color} stopOpacity={0} />
            </linearGradient>
          </defs>
          <Area
            type="monotone"
            dataKey="v"
            stroke={color}
            strokeWidth={1.5}
            fill={`url(#spark-${color.replace('#', '')})`}
            dot={false}
          />
        </AreaChart>
      </ResponsiveContainer>
    </div>
  )
}
