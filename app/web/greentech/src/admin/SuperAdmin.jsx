import { useMemo, useState } from 'react'
import {
  Building2, LayoutDashboard, Leaf, Map, MapPin, Package, Recycle, RefreshCw, Scale, Server,
  Trophy, Truck, Users,
} from 'lucide-react'

import { api } from '@/lib/api'
import { useApi } from '@/lib/useApi'
import { useAuth } from '@/lib/auth-context'
import { AdminShell } from './AdminShell'
import { BinBreakdown, ChartLegend, MagnitudeBars, TrendChart } from './charts'
import { chartColors } from './chart-tokens'
import { Card, CardHeader, DataTable, PageHeading, StatCard, StatusPill } from './widgets'
import { ConfirmDialog } from './ConfirmDialog'
import {
  CollectionPointsPanel, ConsoleState, MapPanel, MunicipalitiesPanel, PeoplePanel, PricingPanel,
} from './panels'

const trendSeries = [
  { key: 'scans', label: 'Scans' },
  { key: 'pickups', label: 'Pickups' },
]

const nav = [
  {
    group: 'Platform',
    items: [
      { id: 'dashboard', label: 'Dashboard', icon: LayoutDashboard },
      { id: 'municipalities', label: 'Municipalities', icon: Building2 },
      { id: 'points', label: 'Collection points', icon: MapPin },
      { id: 'map', label: 'Map', icon: Map },
    ],
  },
  {
    group: 'People',
    items: [
      { id: 'admins', label: 'Municipal admins', icon: Users },
      { id: 'collectors', label: 'Collectors', icon: Truck },
      { id: 'recyclers', label: 'Recyclers', icon: Recycle },
      { id: 'citizens', label: 'Citizens', icon: Users },
    ],
  },
  {
    group: 'System',
    items: [
      { id: 'leaderboard', label: 'Leaderboard', icon: Trophy },
      { id: 'pricing', label: 'Configuration', icon: Scale },
      { id: 'health', label: 'Service health', icon: Server },
    ],
  },
]

const binStream = {
  BLUE: 'Dry recyclable',
  GREEN: 'Wet / glass',
  RED: 'Hazardous',
  GREY: 'Non-recyclable',
}

function LeaderboardPanel() {
  const { data, loading, error } = useApi(() => api.leaderboard(20), [])

  const rows = (data?.entries ?? []).map((e) => ({
    key: e.userId,
    rank: <span className="font-mono text-xs">#{e.rank}</span>,
    name: <span className="font-medium">{e.fullName}</span>,
    role: e.role,
    points: e.points,
    pickups: e.completedPickups,
    weight: `${Number(e.totalWeightKg).toFixed(2)} kg`,
  }))

  return (
    <>
      <PageHeading title="Leaderboard" subtitle="Green Points across every municipality" />

      {data?.totals && (
        <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
          <StatCard label="Scoring citizens" value={data.totals.citizens} index={0} />
          <StatCard label="Points issued" value={data.totals.points} index={1} />
          <StatCard
            label="Waste collected"
            value={Number(data.totals.weightKg)}
            decimals={2}
            suffix=" kg"
            index={2}
          />
          <StatCard label="Completed pickups" value={data.totals.completedPickups} index={3} />
        </div>
      )}

      <Card>
        <CardHeader title="Top citizens" />
        {error ? (
          <p className="px-5 py-10 text-center text-sm text-red-600">{error.message}</p>
        ) : (
          <DataTable
            minWidth={640}
            empty={loading ? 'Loading…' : 'Nobody has earned points yet.'}
            columns={[
              { key: 'rank', label: 'Rank' },
              { key: 'name', label: 'Name' },
              { key: 'role', label: 'Role' },
              { key: 'points', label: 'Points', align: 'right' },
              { key: 'pickups', label: 'Pickups', align: 'right' },
              { key: 'weight', label: 'Weight', align: 'right' },
            ]}
            rows={rows}
          />
        )}
      </Card>
    </>
  )
}

function HealthPanel() {
  const { data, loading, error, reload } = useApi(() => api.systemHealth(), [])

  const services = data?.services ?? []
  const down = services.filter((s) => s.status === 'DOWN').length

  return (
    <>
      <PageHeading
        title="Service health"
        subtitle={
          loading
            ? 'Checking…'
            : down
              ? `${down} service${down === 1 ? '' : 's'} down`
              : 'Every dependency checked server-side, just now'
        }
        action={
          <button
            onClick={reload}
            className="inline-flex items-center gap-2 rounded-lg border border-border px-3.5 py-2 text-sm transition hover:bg-muted"
          >
            <RefreshCw className="h-4 w-4" />
            Re-check
          </button>
        }
      />

      <Card>
        <CardHeader
          title="Services"
          subtitle={data ? `Checked at ${new Date(data.checkedAt).toLocaleTimeString()}` : undefined}
        />
        {error ? (
          <p className="px-5 py-10 text-center text-sm text-red-600">{error.message}</p>
        ) : (
          <DataTable
            minWidth={720}
            empty={loading ? 'Checking…' : 'No data'}
            columns={[
              { key: 'name', label: 'Service' },
              { key: 'detail', label: 'Detail' },
              { key: 'status', label: 'Status' },
              { key: 'latency', label: 'Latency', align: 'right' },
              { key: 'note', label: 'Note' },
            ]}
            rows={services.map((s) => ({
              key: s.name,
              name: <span className="font-medium">{s.name}</span>,
              detail: <span className="text-xs text-muted-foreground">{s.detail}</span>,
              status: <StatusPill status={s.status} />,
              latency: s.latencyMs == null ? '—' : `${s.latencyMs} ms`,
              note: <span className="text-xs text-muted-foreground">{s.note}</span>,
            }))}
          />
        )}
      </Card>
    </>
  )
}

export default function SuperAdmin() {
  const [active, setActive] = useState('dashboard')
  const [confirmLogout, setConfirmLogout] = useState(false)
  const [search, setSearch] = useState('')
  const { user, logout } = useAuth()

  const overview = useApi(() => api.overview(), [])
  const data = overview.data

  const binData = useMemo(
    () =>
      (data?.binSplit ?? []).map((slice) => ({
        bin: slice.label,
        value: slice.value,
        stream: binStream[slice.label] ?? '',
      })),
    [data],
  )

  const roleData = useMemo(
    () => (data?.roleSplit ?? []).map((s) => ({ name: s.label, value: s.value })),
    [data],
  )

  if (overview.loading || overview.error) {
    return <ConsoleState loading={overview.loading} error={overview.error} onRetry={overview.reload} />
  }

  const s = data.stats

  const notifications = []
  if (s.pickupsRequested > s.pickupsCompleted) {
    notifications.push({
      id: 'open-pickups',
      title: `${s.pickupsRequested - s.pickupsCompleted} pickups still open`,
      detail: 'Requested but not yet completed across the platform.',
    })
  }
  if (data.marketplace.openListings > 0) {
    notifications.push({
      id: 'open-listings',
      title: `${data.marketplace.openListings} listings waiting for a buyer`,
      detail: 'Recyclers have not claimed these yet.',
    })
  }
  if (s.collectors === 0) {
    notifications.push({
      id: 'no-collectors',
      title: 'No collectors registered',
      detail: 'Pickups cannot be accepted until a collector account exists.',
    })
  }

  const stats = [
    { label: 'Total scans', value: s.totalScans, icon: Package },
    { label: 'Citizens', value: s.citizens, icon: Users },
    { label: 'Waste diverted', value: Number(s.wasteDivertedKg), decimals: 2, suffix: ' kg', icon: Scale },
    { label: 'Carbon saved', value: Number(s.carbonSavedKg), decimals: 2, suffix: ' kg', icon: Leaf },
  ]

  const panels = {
    dashboard: (
      <>
        <PageHeading
          title="Platform dashboard"
          subtitle="Every municipality, live from the database."
        />

        <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
          {stats.map((stat, i) => (
            <StatCard key={stat.label} index={i} {...stat} />
          ))}
        </div>

        <div className="grid gap-4 xl:grid-cols-3">
          <Card className="xl:col-span-2">
            <CardHeader
              title="Scans and pickups"
              subtitle="Last 14 days"
              action={<ChartLegend items={trendSeries.map((t, i) => ({
                label: t.label,
                color: i === 0 ? chartColors.series1 : chartColors.series2,
              }))} />}
            />
            <div className="px-2 pb-4">
              <TrendChart data={data.trend} series={trendSeries} />
            </div>
          </Card>

          <Card>
            <CardHeader title="Accounts by role" />
            <div className="px-2 pb-4">
              {roleData.length ? (
                <MagnitudeBars data={roleData} unit=" users" />
              ) : (
                <p className="py-10 text-center text-sm text-muted-foreground">No accounts.</p>
              )}
            </div>
          </Card>
        </div>

        <div className="grid gap-4 xl:grid-cols-2">
          <Card>
            <CardHeader title="Bin split" subtitle="Detected materials by bin" />
            <div className="px-5 pb-5">
              {binData.length ? (
                <BinBreakdown data={binData} unit="items" />
              ) : (
                <p className="py-10 text-center text-sm text-muted-foreground">No detections yet.</p>
              )}
            </div>
          </Card>

          <Card>
            <CardHeader title="Marketplace" subtitle="Recycler trading" />
            <DataTable
              minWidth={360}
              columns={[
                { key: 'label', label: 'Metric' },
                { key: 'value', label: 'Value', align: 'right' },
              ]}
              rows={[
                { key: 'open', label: 'Open listings', value: data.marketplace.openListings },
                { key: 'sold', label: 'Sold listings', value: data.marketplace.soldListings },
                {
                  key: 'value',
                  label: 'Traded value',
                  value: `₹${Number(data.marketplace.tradedValue).toFixed(2)}`,
                },
                { key: 'points', label: 'Collection points', value: s.collectionPoints },
              ]}
            />
          </Card>
        </div>
      </>
    ),
    municipalities: <MunicipalitiesPanel />,
    points: <CollectionPointsPanel />,
    map: <MapPanel areaSearch />,
    admins: <PeoplePanel role="MUNICIPAL_ADMIN" title="Municipal admins" canCreate />,
    collectors: <PeoplePanel role="COLLECTOR" title="Collectors" canCreate />,
    recyclers: <PeoplePanel role="RECYCLER" title="Recyclers" canCreate />,
    citizens: <PeoplePanel role="CITIZEN" title="Citizens" initialSearch={search} />,
    leaderboard: <LeaderboardPanel />,
    pricing: <PricingPanel stats={s} marketplace={data.marketplace} />,
    health: <HealthPanel />,
  }

  return (
    <AdminShell
      role="super"
      roleLabel="Super Admin"
      scope="Platform"
      nav={nav}
      active={active}
      onNavigate={setActive}
      user={{
        name: user?.fullName ?? 'Administrator',
        role: user?.role ?? '',
        initials: (user?.fullName ?? 'A').split(' ').map((w) => w[0]).slice(0, 2).join('').toUpperCase(),
        email: user?.email,
        municipality: user?.municipalityName,
        onLogout: () => setConfirmLogout(true),
      }}
      notifications={notifications}
      onSearch={(q) => {
        setSearch(q)
        setActive('citizens')
      }}
      accent="depot"
    >
      <div className="space-y-6">{panels[active]}</div>

      {confirmLogout && (
        <ConfirmDialog
          title="Sign out?"
          body="You will need your email and password to get back into the console."
          confirmLabel="Sign out"
          tone="danger"
          onConfirm={logout}
          onCancel={() => setConfirmLogout(false)}
        />
      )}
    </AdminShell>
  )
}
