import { Suspense, lazy, useState } from 'react'
import { AlertCircle, Loader2, MapPin, Plus, RefreshCw, X } from 'lucide-react'

import { api } from '@/lib/api'
import { useApi } from '@/lib/useApi'
import { Card, CardHeader, DataTable, PageHeading, StatCard, StatusPill } from './widgets'
// mapbox-gl is ~1.7 MB. Loading it only when the Map tab is opened keeps it off
// every other admin screen.
const PointsMap = lazy(() =>
  import('./PointsMap').then((m) => ({ default: m.PointsMap })),
)
const MapLegend = lazy(() =>
  import('./PointsMap').then((m) => ({ default: m.MapLegend })),
)

export function ConsoleState({ loading, error, onRetry }) {
  return (
    <div className="grid min-h-svh place-items-center bg-neutral-100 px-6">
      <div className="max-w-md text-center">
        {loading ? (
          <>
            <Loader2 className="mx-auto mb-4 h-8 w-8 animate-spin text-muted-foreground" />
            <p className="text-sm text-muted-foreground">Loading console…</p>
          </>
        ) : (
          <>
            <AlertCircle className="mx-auto mb-4 h-8 w-8 text-red-500" />
            <p className="mb-1 font-medium">Could not load the console</p>
            <p className="mb-5 text-sm text-muted-foreground">{error?.message}</p>
            <button
              onClick={onRetry}
              className="inline-flex items-center gap-2 rounded-lg bg-neutral-900 px-4 py-2 text-sm text-white transition hover:bg-neutral-700"
            >
              <RefreshCw className="h-4 w-4" />
              Try again
            </button>
          </>
        )}
      </div>
    </div>
  )
}

function Field({ label, ...props }) {
  return (
    <label className="block">
      <span className="mb-1.5 block text-xs font-medium text-muted-foreground">{label}</span>
      <input
        {...props}
        className="w-full rounded-lg border border-border bg-white px-3 py-2 text-sm outline-none transition focus:border-neutral-400"
      />
    </label>
  )
}

function Modal({ title, onClose, onSubmit, busy, error, children, submitLabel = 'Create' }) {
  return (
    <div className="fixed inset-0 z-50 grid place-items-center bg-neutral-950/40 p-4">
      <div className="w-full max-w-md rounded-2xl border border-border bg-white p-6 shadow-xl">
        <div className="mb-5 flex items-start justify-between">
          <h3 className="font-medium">{title}</h3>
          <button onClick={onClose} className="text-muted-foreground transition hover:text-foreground">
            <X className="h-4 w-4" />
          </button>
        </div>

        <form onSubmit={onSubmit} className="space-y-3">
          {children}

          {error && (
            <p className="rounded-lg border border-red-200 bg-red-50 px-3 py-2 text-xs text-red-700">
              {error}
            </p>
          )}

          <div className="flex justify-end gap-2 pt-2">
            <button
              type="button"
              onClick={onClose}
              className="rounded-lg border border-border px-4 py-2 text-sm transition hover:bg-muted"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={busy}
              className="inline-flex items-center gap-2 rounded-lg bg-neutral-900 px-4 py-2 text-sm text-white transition hover:bg-neutral-700 disabled:opacity-60"
            >
              {busy && <Loader2 className="h-3.5 w-3.5 animate-spin" />}
              {submitLabel}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}

export function PeoplePanel({ role, title, canCreate = false, initialSearch = '' }) {
  const [search, setSearch] = useState(initialSearch)
  const [open, setOpen] = useState(false)
  const [form, setForm] = useState({ fullName: '', email: '', password: '', phone: '' })
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState(null)
  const [notice, setNotice] = useState(null)

  const { data, loading, error: loadError, reload } = useApi(
    () => api.users({ role, search: search || undefined, size: 100 }),
    [role, search],
  )

  const submit = async (event) => {
    event.preventDefault()
    setBusy(true)
    setError(null)
    try {
      await api.createUser({ ...form, role })
      setOpen(false)
      setForm({ fullName: '', email: '', password: '', phone: '' })
      setNotice(`${role.toLowerCase()} account created`)
      reload()
    } catch (e) {
      setError(e.message)
    } finally {
      setBusy(false)
    }
  }

  const toggle = async (user) => {
    setNotice(null)
    try {
      await api.updateUser(user.id, { active: !user.active })
      reload()
    } catch (e) {
      setNotice(e.message)
    }
  }

  const rows = (data?.items ?? []).map((u) => ({
    key: u.id,
    name: (
      <div>
        <p className="font-medium">{u.fullName}</p>
        <p className="text-xs text-muted-foreground">{u.email}</p>
      </div>
    ),
    phone: u.phone || '—',
    municipality: u.municipalityName || '—',
    points: u.points,
    status: <StatusPill status={u.active ? 'ACTIVE' : 'DISABLED'} />,
    action: (
      <button
        onClick={() => toggle(u)}
        className="rounded-md border border-border px-2.5 py-1 text-xs transition hover:bg-muted"
      >
        {u.active ? 'Disable' : 'Enable'}
      </button>
    ),
  }))

  return (
    <>
      <PageHeading
        title={title}
        subtitle={loading ? 'Loading…' : `${data?.totalItems ?? 0} account${data?.totalItems === 1 ? '' : 's'}`}
        action={
          canCreate && (
            <button
              onClick={() => setOpen(true)}
              className="inline-flex items-center gap-2 rounded-lg bg-neutral-900 px-3.5 py-2 text-sm text-white transition hover:bg-neutral-700"
            >
              <Plus className="h-4 w-4" />
              Add {role.toLowerCase()}
            </button>
          )
        }
      />

      {notice && (
        <p className="rounded-lg border border-emerald-200 bg-emerald-50 px-3 py-2 text-xs text-emerald-800">
          {notice}
        </p>
      )}

      <Card>
        <CardHeader
          title="Accounts"
          action={
            <input
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Search name or email"
              className="w-52 rounded-lg border border-border bg-white px-3 py-1.5 text-sm outline-none transition focus:border-neutral-400"
            />
          }
        />
        {loadError ? (
          <p className="px-5 py-10 text-center text-sm text-red-600">{loadError.message}</p>
        ) : (
          <DataTable
            minWidth={760}
            empty={loading ? 'Loading…' : `No ${role.toLowerCase()} accounts yet.`}
            columns={[
              { key: 'name', label: 'Name' },
              { key: 'phone', label: 'Phone' },
              { key: 'municipality', label: 'Municipality' },
              { key: 'points', label: 'Points', align: 'right' },
              { key: 'status', label: 'Status' },
              { key: 'action', label: '', align: 'right' },
            ]}
            rows={rows}
          />
        )}
      </Card>

      {open && (
        <Modal
          title={`New ${role.toLowerCase()}`}
          onClose={() => setOpen(false)}
          onSubmit={submit}
          busy={busy}
          error={error}
        >
          <Field
            label="Full name"
            required
            value={form.fullName}
            onChange={(e) => setForm({ ...form, fullName: e.target.value })}
          />
          <Field
            label="Email"
            type="email"
            required
            value={form.email}
            onChange={(e) => setForm({ ...form, email: e.target.value })}
          />
          <Field
            label="Password"
            type="password"
            required
            minLength={8}
            value={form.password}
            onChange={(e) => setForm({ ...form, password: e.target.value })}
          />
          <Field
            label="Phone"
            value={form.phone}
            onChange={(e) => setForm({ ...form, phone: e.target.value })}
          />
        </Modal>
      )}
    </>
  )
}

export function CollectionPointsPanel() {
  const [open, setOpen] = useState(false)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState(null)
  const [form, setForm] = useState({
    name: '', locality: '', ward: '', municipalityCode: 'HMC', lat: '', lon: '',
  })

  const { data, loading, error: loadError, reload } = useApi(() => api.points(), [])

  const submit = async (event) => {
    event.preventDefault()
    setBusy(true)
    setError(null)
    try {
      await api.createPoint({
        ...form,
        lat: Number(form.lat),
        lon: Number(form.lon),
        type: 'BIN_CLUSTER',
      })
      setOpen(false)
      setForm({ name: '', locality: '', ward: '', municipalityCode: 'HMC', lat: '', lon: '' })
      reload()
    } catch (e) {
      setError(e.message)
    } finally {
      setBusy(false)
    }
  }

  const deactivate = async (id) => {
    await api.deletePoint(id)
    reload()
  }

  const points = data?.points ?? []
  const active = points.filter((p) => p.active).length

  const rows = points.slice(0, 200).map((p) => ({
    key: p.id,
    code: <span className="font-mono text-xs">{p.code}</span>,
    name: (
      <div>
        <p className="font-medium">{p.name}</p>
        <p className="text-xs text-muted-foreground">{p.locality}</p>
      </div>
    ),
    ward: p.ward || '—',
    type: p.type,
    coords: <span className="font-mono text-xs">{p.lat.toFixed(4)}, {p.lon.toFixed(4)}</span>,
    status: <StatusPill status={p.active ? 'ACTIVE' : 'DISABLED'} />,
    action: p.active && (
      <button
        onClick={() => deactivate(p.id)}
        className="rounded-md border border-border px-2.5 py-1 text-xs transition hover:bg-muted"
      >
        Disable
      </button>
    ),
  }))

  return (
    <>
      <PageHeading
        title="Collection points"
        subtitle={loading ? 'Loading…' : `${active} active of ${points.length}`}
        action={
          <button
            onClick={() => setOpen(true)}
            className="inline-flex items-center gap-2 rounded-lg bg-neutral-900 px-3.5 py-2 text-sm text-white transition hover:bg-neutral-700"
          >
            <Plus className="h-4 w-4" />
            Add point
          </button>
        }
      />

      <Card>
        <CardHeader title="Network" subtitle="First 200 shown" />
        {loadError ? (
          <p className="px-5 py-10 text-center text-sm text-red-600">{loadError.message}</p>
        ) : (
          <DataTable
            minWidth={820}
            empty={loading ? 'Loading…' : 'No collection points yet.'}
            columns={[
              { key: 'code', label: 'Code' },
              { key: 'name', label: 'Name' },
              { key: 'ward', label: 'Ward' },
              { key: 'type', label: 'Type' },
              { key: 'coords', label: 'Coordinates' },
              { key: 'status', label: 'Status' },
              { key: 'action', label: '', align: 'right' },
            ]}
            rows={rows}
          />
        )}
      </Card>

      {open && (
        <Modal
          title="New collection point"
          onClose={() => setOpen(false)}
          onSubmit={submit}
          busy={busy}
          error={error}
        >
          <Field
            label="Name"
            required
            value={form.name}
            onChange={(e) => setForm({ ...form, name: e.target.value })}
          />
          <Field
            label="Locality"
            value={form.locality}
            onChange={(e) => setForm({ ...form, locality: e.target.value })}
          />
          <Field
            label="Ward"
            value={form.ward}
            onChange={(e) => setForm({ ...form, ward: e.target.value })}
          />
          <Field
            label="Municipality code"
            required
            value={form.municipalityCode}
            onChange={(e) => setForm({ ...form, municipalityCode: e.target.value.toUpperCase() })}
          />
          <div className="grid grid-cols-2 gap-3">
            <Field
              label="Latitude"
              required
              type="number"
              step="0.000001"
              placeholder="22.5671"
              value={form.lat}
              onChange={(e) => setForm({ ...form, lat: e.target.value })}
            />
            <Field
              label="Longitude"
              required
              type="number"
              step="0.000001"
              placeholder="88.2977"
              value={form.lon}
              onChange={(e) => setForm({ ...form, lon: e.target.value })}
            />
          </div>
        </Modal>
      )}
    </>
  )
}

export function MapPanel({ areaSearch = false }) {
  const [area, setArea] = useState('ALL')
  const [query, setQuery] = useState('')
  const [selected, setSelected] = useState(null)
  const { data, loading, error } = useApi(() => api.points(), [])

  const points = data?.points ?? []
  const depots = data?.depots ?? []

  const areas = Array.from(
    new Map(points.map((p) => [p.municipalityCode, {
      code: p.municipalityCode,
      name: p.municipality,
      district: p.district,
    }])).values(),
  )

  const term = query.trim().toLowerCase()
  const visible = points.filter((p) => {
    if (area !== 'ALL' && p.municipalityCode !== area) return false
    if (!term) return true
    return [p.name, p.locality, p.ward, p.code, p.municipality, p.district]
      .filter(Boolean)
      .some((v) => v.toLowerCase().includes(term))
  })

  const visibleDepots = depots.filter((d) => area === 'ALL' || d.code === area)
  const activeCount = visible.filter((p) => p.active).length

  return (
    <>
      <PageHeading
        title="Collection point map"
        subtitle={
          loading
            ? 'Loading…'
            : `${visible.length} point${visible.length === 1 ? '' : 's'} shown` +
              `, ${activeCount} active` +
              (data?.scope === 'MUNICIPALITY' ? ' in your municipality' : ' across the platform')
        }
      />

      <Card>
        <CardHeader
          title="Network"
          subtitle={visibleDepots.length === 1 ? visibleDepots[0].municipality : 'All areas'}
          action={
            <div className="flex flex-wrap items-center gap-2">
              {areaSearch && areas.length > 1 && (
                <select
                  value={area}
                  onChange={(e) => setArea(e.target.value)}
                  className="rounded-lg border border-border bg-white px-3 py-1.5 text-sm outline-none transition focus:border-neutral-400"
                >
                  <option value="ALL">All municipalities</option>
                  {areas.map((a) => (
                    <option key={a.code} value={a.code}>
                      {a.name} · {a.district}
                    </option>
                  ))}
                </select>
              )}
              <input
                value={query}
                onChange={(e) => setQuery(e.target.value)}
                placeholder="Search locality, ward or code"
                className="w-56 rounded-lg border border-border bg-white px-3 py-1.5 text-sm outline-none transition focus:border-neutral-400"
              />
            </div>
          }
        />

        <div className="px-5 pb-5">
          {error ? (
            <p className="py-10 text-center text-sm text-red-600">{error.message}</p>
          ) : loading ? (
            <div className="grid h-[460px] place-items-center rounded-xl bg-muted/40">
              <Loader2 className="h-6 w-6 animate-spin text-muted-foreground" />
            </div>
          ) : visible.length === 0 ? (
            <div className="grid h-[460px] place-items-center rounded-xl border border-dashed border-border bg-muted/30">
              <div className="text-center">
                <MapPin className="mx-auto mb-2 h-6 w-6 text-muted-foreground" />
                <p className="text-sm text-muted-foreground">Nothing matches that search.</p>
              </div>
            </div>
          ) : (
            <Suspense
              fallback={
                <div className="grid h-[460px] place-items-center rounded-xl bg-muted/40">
                  <Loader2 className="h-6 w-6 animate-spin text-muted-foreground" />
                </div>
              }
            >
              <PointsMap points={visible} depots={visibleDepots} onSelect={setSelected} />
              <div className="mt-4">
                <MapLegend />
              </div>
            </Suspense>
          )}
        </div>
      </Card>

      {selected && (
        <Card>
          <CardHeader
            title={selected.name}
            subtitle={`${selected.code} · ${selected.municipality}`}
            action={
              <button
                onClick={() => setSelected(null)}
                className="rounded-md border border-border px-2.5 py-1 text-xs transition hover:bg-muted"
              >
                Close
              </button>
            }
          />
          <DataTable
            minWidth={480}
            columns={[
              { key: 'field', label: 'Field' },
              { key: 'value', label: 'Value', align: 'right' },
            ]}
            rows={[
              { key: 'locality', field: 'Locality', value: selected.locality || '—' },
              { key: 'ward', field: 'Ward', value: selected.ward || '—' },
              { key: 'type', field: 'Type', value: selected.type },
              { key: 'district', field: 'District', value: selected.district },
              {
                key: 'coords',
                field: 'Coordinates',
                value: (
                  <span className="font-mono text-xs">
                    {selected.lat.toFixed(5)}, {selected.lon.toFixed(5)}
                  </span>
                ),
              },
              {
                key: 'status',
                field: 'Status',
                value: <StatusPill status={selected.active ? 'ACTIVE' : 'DISABLED'} />,
              },
            ]}
          />
        </Card>
      )}
    </>
  )
}

export function MunicipalitiesPanel() {
  const [open, setOpen] = useState(false)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState(null)
  const [form, setForm] = useState({
    code: '', name: '', district: '', depotLat: '', depotLon: '',
  })

  const { data, loading, error: loadError, reload } = useApi(() => api.municipalities(), [])

  const submit = async (event) => {
    event.preventDefault()
    setBusy(true)
    setError(null)
    try {
      await api.createMunicipality({
        ...form,
        code: form.code.toUpperCase(),
        depotLat: Number(form.depotLat),
        depotLon: Number(form.depotLon),
      })
      setOpen(false)
      setForm({ code: '', name: '', district: '', depotLat: '', depotLon: '' })
      reload()
    } catch (e) {
      setError(e.message)
    } finally {
      setBusy(false)
    }
  }

  const rows = (data?.municipalities ?? []).map((m) => ({
    key: m.id,
    code: <span className="font-mono text-xs">{m.code}</span>,
    name: <span className="font-medium">{m.name}</span>,
    district: m.district,
    depot: <span className="font-mono text-xs">{m.depotLat.toFixed(4)}, {m.depotLon.toFixed(4)}</span>,
    status: <StatusPill status={m.active ? 'ACTIVE' : 'DISABLED'} />,
  }))

  return (
    <>
      <PageHeading
        title="Municipalities"
        subtitle={loading ? 'Loading…' : `${data?.count ?? 0} registered`}
        action={
          <button
            onClick={() => setOpen(true)}
            className="inline-flex items-center gap-2 rounded-lg bg-neutral-900 px-3.5 py-2 text-sm text-white transition hover:bg-neutral-700"
          >
            <Plus className="h-4 w-4" />
            Add municipality
          </button>
        }
      />

      <Card>
        <CardHeader title="Registered bodies" subtitle="Each has one depot, used as the route start" />
        {loadError ? (
          <p className="px-5 py-10 text-center text-sm text-red-600">{loadError.message}</p>
        ) : (
          <DataTable
            minWidth={720}
            empty={loading ? 'Loading…' : 'No municipalities yet.'}
            columns={[
              { key: 'code', label: 'Code' },
              { key: 'name', label: 'Name' },
              { key: 'district', label: 'District' },
              { key: 'depot', label: 'Depot' },
              { key: 'status', label: 'Status' },
            ]}
            rows={rows}
          />
        )}
      </Card>

      {open && (
        <Modal
          title="New municipality"
          onClose={() => setOpen(false)}
          onSubmit={submit}
          busy={busy}
          error={error}
        >
          <Field
            label="Code"
            required
            placeholder="BDN"
            value={form.code}
            onChange={(e) => setForm({ ...form, code: e.target.value.toUpperCase() })}
          />
          <Field
            label="Name"
            required
            value={form.name}
            onChange={(e) => setForm({ ...form, name: e.target.value })}
          />
          <Field
            label="District"
            required
            value={form.district}
            onChange={(e) => setForm({ ...form, district: e.target.value })}
          />
          <div className="grid grid-cols-2 gap-3">
            <Field
              label="Depot latitude"
              required
              type="number"
              step="0.000001"
              value={form.depotLat}
              onChange={(e) => setForm({ ...form, depotLat: e.target.value })}
            />
            <Field
              label="Depot longitude"
              required
              type="number"
              step="0.000001"
              value={form.depotLon}
              onChange={(e) => setForm({ ...form, depotLon: e.target.value })}
            />
          </div>
        </Modal>
      )}
    </>
  )
}

export function PricingPanel({ stats, marketplace }) {
  const rates = [
    { label: 'Doorstep pickup', value: '5 points / kg', note: 'DOORSTEP_POINTS_PER_KG' },
    { label: 'Drop at a collection point', value: '8 points / kg', note: 'DROPOFF_POINTS_PER_KG' },
    { label: 'Pickup completion bonus', value: '+20 points', note: 'COMPLETION_BONUS_POINTS' },
    { label: 'Vehicle capacity', value: '80 kg', note: 'VEHICLE_CAPACITY_KG' },
  ]

  return (
    <>
      <PageHeading
        title="Pricing & rewards"
        subtitle="Configured on the API. These are the rates currently in force."
      />

      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <StatCard label="Open listings" value={marketplace?.openListings ?? 0} index={0} />
        <StatCard label="Sold listings" value={marketplace?.soldListings ?? 0} index={1} />
        <StatCard
          label="Traded value"
          value={Number(marketplace?.tradedValue ?? 0)}
          decimals={2}
          prefix="₹"
          index={2}
        />
        <StatCard label="Points issued" value={stats?.pointsIssued ?? 0} index={3} />
      </div>

      <Card>
        <CardHeader title="Reward rates" subtitle="Change these with environment variables, then restart" />
        <DataTable
          minWidth={560}
          columns={[
            { key: 'label', label: 'Action' },
            { key: 'value', label: 'Rate', align: 'right' },
            { key: 'note', label: 'Variable' },
          ]}
          rows={rates.map((r) => ({
            key: r.label,
            label: r.label,
            value: <span className="font-medium">{r.value}</span>,
            note: <span className="font-mono text-xs text-muted-foreground">{r.note}</span>,
          }))}
        />
      </Card>
    </>
  )
}
