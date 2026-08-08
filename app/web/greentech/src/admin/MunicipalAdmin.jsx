import { useMemo, useState } from 'react'
import {
  LayoutDashboard, Leaf, Map, MapPin, Package, Recycle, Scale, Truck, Users,
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
  CollectionPointsPanel, ConsoleState, MapPanel, PeoplePanel, PricingPanel,
} from './panels'

const trendSeries = [
  { key: 'scans', label: 'Scans' },
  { key: 'pickups', label: 'Pickups' },
]

const nav = [
  {
    group: 'Operations',
    items: [
      { id: 'dashboard', label: 'Dashboard', icon: LayoutDashboard },
      { id: 'collectors', label: 'Collectors', icon: Truck },
      { id: 'recyclers', label: 'Recyclers', icon: Recycle },
    ],
  },
  {
    group: 'Network',
    items: [
      { id: 'points', label: 'Collection points', icon: MapPin },
      { id: 'map', label: 'Map', icon: Map },
      { id: 'citizens', label: 'Citizens', icon: Users },
      { id: 'pricing', label: 'Pricing & rewards', icon: Scale },
    ],
  },
]

const binStream = {
  BLUE: 'Dry recyclable',
  GREEN: 'Wet / glass',
  RED: 'Hazardous',
  GREY: 'Non-recyclable',
}

export default function MunicipalAdmin() {
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

  const materialData = useMemo(
    () => (data?.topMaterials ?? []).map((m) => ({ name: m.material, value: m.count })),
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
      detail: 'Requested but not yet completed.',
    })
  }
  if (s.collectors === 0) {
    notifications.push({
      id: 'no-collectors',
      title: 'No collectors registered',
      detail: 'Add a collector before citizens request a doorstep pickup.',
    })
  }
  if (s.recyclers === 0) {
    notifications.push({
      id: 'no-recyclers',
      title: 'No recyclers registered',
      detail: 'Marketplace listings cannot be bought until one exists.',
    })
  }

  const stats = [
    { label: 'Scans logged', value: s.totalScans, icon: Package },
    { label: 'Waste diverted', value: Number(s.wasteDivertedKg), decimals: 2, suffix: ' kg', icon: Scale },
    { label: 'Collection points', value: s.collectionPoints, icon: MapPin },
    { label: 'Points issued', value: s.pointsIssued, icon: Leaf },
  ]

  const panels = {
    dashboard: (
      <>
        <PageHeading
          title="Dashboard"
          subtitle={`${data.municipalityName ?? 'Municipality'} — live figures from the platform database.`}
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
            <CardHeader title="Bin split" subtitle="Detected materials by bin" />
            <div className="px-5 pb-5">
              {binData.length ? (
                <BinBreakdown data={binData} unit="items" />
              ) : (
                <p className="py-10 text-center text-sm text-muted-foreground">
                  No detections yet.
                </p>
              )}
            </div>
          </Card>
        </div>

        <div className="grid gap-4 xl:grid-cols-2">
          <Card>
            <CardHeader title="Top materials" subtitle="By number of detections" />
            <div className="px-2 pb-4">
              {materialData.length ? (
                <MagnitudeBars data={materialData} unit=" items" />
              ) : (
                <p className="py-10 text-center text-sm text-muted-foreground">
                  Nothing detected yet.
                </p>
              )}
            </div>
          </Card>

          <Card>
            <CardHeader title="Pickups" subtitle="By status" />
            <DataTable
              minWidth={360}
              empty="No pickups requested yet."
              columns={[
                { key: 'label', label: 'Status' },
                { key: 'value', label: 'Count', align: 'right' },
              ]}
              rows={(data.pickupStatus ?? []).map((p) => ({
                key: p.label,
                label: <StatusPill status={p.label} />,
                value: p.value,
              }))}
            />
          </Card>
        </div>
      </>
    ),
    collectors: <PeoplePanel role="COLLECTOR" title="Collectors" canCreate />,
    recyclers: <PeoplePanel role="RECYCLER" title="Recyclers" canCreate />,
    citizens: <PeoplePanel role="CITIZEN" title="Citizens" initialSearch={search} />,
    points: <CollectionPointsPanel />,
    map: <MapPanel />,
    pricing: <PricingPanel stats={s} marketplace={data.marketplace} />,
  }

  return (
    <AdminShell
      role="municipal"
      roleLabel="Municipal Admin"
      scope={data.municipalityName ?? 'Municipality'}
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
      accent="brand"
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
