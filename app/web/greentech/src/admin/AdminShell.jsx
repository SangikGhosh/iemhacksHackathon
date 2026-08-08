import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { AnimatePresence, motion } from 'motion/react'
import { ArrowLeft, Bell, LogOut, Menu, Search, X } from 'lucide-react'

import { cn } from '@/lib/utils'
import { Assistant } from './Assistant'

/**
 * Chrome shared by both consoles: a fixed sidebar on desktop, a slide-over on
 * mobile, and a sticky topbar. Presentation only — no data is fetched and the
 * navigation switches a local tab rather than a route.
 */
export function AdminShell({
  role,
  roleLabel,
  scope,
  nav,
  active,
  onNavigate,
  user,
  accent = 'brand',
  notifications = [],
  onSearch,
  children,
}) {
  const [mobileOpen, setMobileOpen] = useState(false)
  const [notifyOpen, setNotifyOpen] = useState(false)
  const [profileOpen, setProfileOpen] = useState(false)
  const [query, setQuery] = useState('')

  useEffect(() => {
    document.body.style.overflow = mobileOpen ? 'hidden' : ''
    return () => {
      document.body.style.overflow = ''
    }
  }, [mobileOpen])

  useEffect(() => {
    const onKey = (e) => {
      if (e.key !== 'Escape') return
      setMobileOpen(false)
      setNotifyOpen(false)
      setProfileOpen(false)
    }
    document.addEventListener('keydown', onKey)
    return () => document.removeEventListener('keydown', onKey)
  }, [])

  const accentRing = accent === 'depot' ? 'from-depot-600 to-depot-900' : 'from-brand-500 to-depot-700'

  const sidebar = (
    <div className="flex h-full flex-col">
      <div className="flex items-center gap-2.5 border-b border-white/10 px-5 py-5">
        <span className="flex h-[30px] w-[30px] shrink-0 items-center justify-center rounded-lg bg-white p-0.5">
          <img src="/logo-mark.png" alt="" width={26} height={26} className="h-full w-full object-contain" />
        </span>
        <div className="min-w-0 flex-1">
          <p className="truncate text-sm font-semibold text-white">GreenTech</p>
          <p className="truncate text-[11px] text-white/45">{roleLabel}</p>
        </div>
        <button
          className="text-white/60 transition-colors hover:text-white lg:hidden"
          onClick={() => setMobileOpen(false)}
          aria-label="Close navigation"
        >
          <X className="h-5 w-5" />
        </button>
      </div>

      <nav className="flex-1 space-y-6 overflow-y-auto px-3 py-5">
        {nav.map((group) => (
          <div key={group.group}>
            <p className="mb-2 px-2.5 text-[10px] font-medium uppercase tracking-[0.16em] text-white/35">
              {group.group}
            </p>
            <div className="space-y-0.5">
              {group.items.map((item) => {
                const isActive = active === item.id
                return (
                  <button
                    key={item.id}
                    onClick={() => {
                      onNavigate(item.id)
                      setMobileOpen(false)
                    }}
                    aria-current={isActive ? 'page' : undefined}
                    className={cn(
                      'relative flex w-full items-center gap-3 rounded-lg px-2.5 py-2 text-left text-sm transition-colors',
                      isActive
                        ? 'bg-white/10 text-white'
                        : 'text-white/55 hover:bg-white/5 hover:text-white/90',
                    )}
                  >
                    {isActive && (
                      <motion.span
                        layoutId={`admin-active-${role}`}
                        className="absolute inset-y-1 left-0 w-0.5 rounded-full bg-brand-300"
                        transition={{ type: 'spring', stiffness: 400, damping: 32 }}
                      />
                    )}
                    <item.icon className="h-4 w-4 shrink-0" strokeWidth={1.7} />
                    <span className="flex-1 truncate">{item.label}</span>
                    {item.badge != null && (
                      <span
                        className={cn(
                          'shrink-0 rounded-full px-1.5 py-0.5 text-[10px] font-medium tabular-nums',
                          item.badgeTone === 'alert'
                            ? 'bg-red-500/20 text-red-300'
                            : 'bg-white/10 text-white/70',
                        )}
                      >
                        {item.badge}
                      </span>
                    )}
                  </button>
                )
              })}
            </div>
          </div>
        ))}
      </nav>

      <div className="border-t border-white/10 p-3">
        <div className="flex items-center gap-3 rounded-xl p-2 transition-colors hover:bg-white/5">
          <span
            className={cn(
              'flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-gradient-to-br text-xs font-semibold text-white',
              accentRing,
            )}
          >
            {user.initials}
          </span>
          <div className="min-w-0 flex-1">
            <p className="truncate text-sm text-white">{user.name}</p>
            <p className="truncate font-mono text-[10px] text-white/40">{user.role}</p>
          </div>
          <button
            onClick={user.onLogout}
            title="Sign out"
            aria-label="Sign out"
            className="shrink-0 text-white/40 transition-colors hover:text-white"
          >
            <LogOut className="h-4 w-4" />
          </button>
        </div>

        <Link
          to="/"
          className="mt-1 flex items-center gap-2.5 rounded-xl px-2 py-2.5 text-sm text-white/55 transition-colors hover:bg-white/5 hover:text-white"
        >
          <ArrowLeft className="h-4 w-4" />
          Back to site
        </Link>
      </div>
    </div>
  )

  return (
    <div className="min-h-svh bg-neutral-100">
      {/* Desktop sidebar */}
      <aside className="fixed inset-y-0 left-0 z-40 hidden w-64 bg-neutral-950 lg:block">
        {sidebar}
      </aside>

      {/* Mobile slide-over */}
      <AnimatePresence>
        {mobileOpen && (
          <>
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              onClick={() => setMobileOpen(false)}
              className="fixed inset-0 z-40 bg-black/50 lg:hidden"
            />
            <motion.aside
              initial={{ x: '-100%' }}
              animate={{ x: 0 }}
              exit={{ x: '-100%' }}
              transition={{ type: 'spring', stiffness: 340, damping: 34 }}
              className="fixed inset-y-0 left-0 z-50 w-[17rem] bg-neutral-950 lg:hidden"
            >
              {sidebar}
            </motion.aside>
          </>
        )}
      </AnimatePresence>

      <div className="lg:pl-64">
        {/* Topbar */}
        <header className="sticky top-0 z-30 border-b border-border bg-white/85 backdrop-blur-xl">
          <div className="flex items-center gap-3 px-4 py-3 sm:px-6">
            <button
              className="-ml-1 p-1 lg:hidden"
              onClick={() => setMobileOpen(true)}
              aria-label="Open navigation"
            >
              <Menu className="h-5 w-5" />
            </button>

            <div className="min-w-0 flex-1">
              <h1 className="truncate text-sm font-semibold sm:text-base">{roleLabel}</h1>
              <p className="truncate text-xs text-muted-foreground">{scope}</p>
            </div>

            <form
              className="relative hidden md:block"
              onSubmit={(e) => {
                e.preventDefault()
                onSearch?.(query)
              }}
            >
              <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
              <input
                type="search"
                value={query}
                onChange={(e) => setQuery(e.target.value)}
                placeholder="Search users by name or email…"
                className="w-56 rounded-full border border-border bg-muted/60 py-2 pl-9 pr-3 text-sm outline-none transition-all placeholder:text-muted-foreground focus:w-72 focus:border-foreground/25 focus:bg-white lg:w-64"
              />
            </form>

            <div className="relative">
              <button
                onClick={() => {
                  setNotifyOpen((open) => !open)
                  setProfileOpen(false)
                }}
                className="relative rounded-full border border-border p-2 transition-colors hover:bg-muted"
                aria-label="Notifications"
                aria-expanded={notifyOpen}
              >
                <Bell className="h-4 w-4" />
                {notifications.length > 0 && (
                  <span className="absolute right-1.5 top-1.5 h-1.5 w-1.5 rounded-full bg-red-500" />
                )}
              </button>

              {notifyOpen && (
                <div className="absolute right-0 z-40 mt-2 w-80 rounded-xl border border-border bg-white p-2 shadow-lg">
                  <p className="px-3 py-2 text-xs font-medium uppercase tracking-wider text-muted-foreground">
                    Notifications
                  </p>
                  {notifications.length === 0 ? (
                    <p className="px-3 py-6 text-center text-sm text-muted-foreground">
                      Nothing needs your attention.
                    </p>
                  ) : (
                    notifications.map((n) => (
                      <div key={n.id} className="rounded-lg px-3 py-2.5 hover:bg-muted">
                        <p className="text-sm font-medium">{n.title}</p>
                        <p className="text-xs text-muted-foreground">{n.detail}</p>
                      </div>
                    ))
                  )}
                </div>
              )}
            </div>

            <div className="relative">
              <button
                onClick={() => {
                  setProfileOpen((open) => !open)
                  setNotifyOpen(false)
                }}
                aria-label="Account"
                aria-expanded={profileOpen}
                className={cn(
                  'hidden h-9 w-9 shrink-0 items-center justify-center rounded-full bg-gradient-to-br text-xs font-semibold text-white sm:flex',
                  accentRing,
                )}
              >
                {user.initials}
              </button>

              {profileOpen && (
                <div className="absolute right-0 z-40 mt-2 w-72 rounded-xl border border-border bg-white p-2 shadow-lg">
                  <div className="border-b border-border px-3 py-2.5">
                    <p className="truncate text-sm font-medium">{user.name}</p>
                    <p className="truncate text-xs text-muted-foreground">{user.email}</p>
                    <p className="mt-1 font-mono text-[10px] uppercase text-muted-foreground">
                      {user.role}
                      {user.municipality ? ` · ${user.municipality}` : ''}
                    </p>
                  </div>
                  <button
                    onClick={() => {
                      setProfileOpen(false)
                      user.onLogout?.()
                    }}
                    className="mt-1 flex w-full items-center gap-2.5 rounded-lg px-3 py-2 text-left text-sm text-red-600 transition-colors hover:bg-red-50"
                  >
                    <LogOut className="h-4 w-4" />
                    Sign out
                  </button>
                </div>
              )}
            </div>
          </div>
        </header>

        <main className="px-4 py-6 sm:px-6 sm:py-8">{children}</main>
      </div>

      <Assistant roleLabel={roleLabel} />
    </div>
  )
}
