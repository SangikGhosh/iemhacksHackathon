import { useState } from 'react'
import { Link, Navigate, useNavigate } from 'react-router-dom'
import { ArrowLeft, Eye, EyeOff, Loader2, ShieldCheck } from 'lucide-react'
import { isAdmin, useAuth } from '@/lib/auth-context'

const field =
  'w-full rounded-lg border border-border bg-white px-3.5 py-2.5 text-sm outline-none ' +
  'transition-colors placeholder:text-muted-foreground focus:border-brand-500 ' +
  'focus:ring-2 focus:ring-brand-500/15 disabled:opacity-60'

export default function AdminLogin() {
  const { login, user } = useAuth()
  const navigate = useNavigate()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [showPassword, setShowPassword] = useState(false)
  const [error, setError] = useState(null)
  const [busy, setBusy] = useState(false)

  if (isAdmin(user)) {
    return <Navigate to={user.role === 'SUPER_ADMIN' ? '/admin/super' : '/admin/municipal'} replace />
  }

  const submit = async (event) => {
    event.preventDefault()
    setBusy(true)
    setError(null)
    try {
      const signedIn = await login(email.trim(), password)
      if (!isAdmin(signedIn)) {
        setError(`This console is for administrators. That account is a ${signedIn.role}.`)
        setBusy(false)
        return
      }
      navigate(signedIn.role === 'SUPER_ADMIN' ? '/admin/super' : '/admin/municipal', { replace: true })
    } catch (e) {
      setError(e.message)
      setBusy(false)
    }
  }

  return (
    <div className="relative grid min-h-svh place-items-center overflow-hidden bg-neutral-100 px-4 py-10">
      {/* Two soft brand washes rather than a flat fill, so the white card still reads as
          raised on a large screen where a plain background looks empty. */}
      <div
        aria-hidden
        className="pointer-events-none absolute -top-32 -left-24 h-96 w-96 rounded-full bg-brand-500/10 blur-3xl"
      />
      <div
        aria-hidden
        className="pointer-events-none absolute -right-24 -bottom-32 h-96 w-96 rounded-full bg-depot-500/10 blur-3xl"
      />

      <div className="relative w-full max-w-sm">
        <div className="mb-6 flex items-center gap-3">
          <span className="grid size-11 shrink-0 place-items-center rounded-xl bg-gradient-to-br from-brand-500 to-depot-700 text-white shadow-sm">
            <ShieldCheck className="size-5" strokeWidth={1.9} />
          </span>
          <div className="min-w-0">
            <h1 className="truncate text-base font-semibold">GreenRoute Console</h1>
            <p className="truncate text-xs text-muted-foreground">
              Municipal &amp; platform administration
            </p>
          </div>
        </div>

        <form
          onSubmit={submit}
          className="rounded-2xl border border-border bg-white p-6 shadow-lg shadow-neutral-950/5"
        >
          <div className="space-y-4">
            <div>
              <label htmlFor="admin-email" className="mb-1.5 block text-xs font-medium">
                Email
              </label>
              <input
                id="admin-email"
                type="email"
                required
                autoFocus
                autoComplete="username"
                disabled={busy}
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="you@municipality.gov.in"
                className={field}
              />
            </div>

            <div>
              <label htmlFor="admin-password" className="mb-1.5 block text-xs font-medium">
                Password
              </label>
              <div className="relative">
                <input
                  id="admin-password"
                  type={showPassword ? 'text' : 'password'}
                  required
                  autoComplete="current-password"
                  disabled={busy}
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  className={`${field} pr-10`}
                />
                <button
                  type="button"
                  onClick={() => setShowPassword((v) => !v)}
                  aria-label={showPassword ? 'Hide password' : 'Show password'}
                  className="absolute inset-y-0 right-0 grid w-10 place-items-center text-muted-foreground transition-colors hover:text-foreground"
                >
                  {showPassword ? <EyeOff className="size-4" /> : <Eye className="size-4" />}
                </button>
              </div>
            </div>

            {error && (
              <p
                role="alert"
                className="rounded-lg border border-red-200 bg-red-50 px-3 py-2 text-xs leading-relaxed text-red-700"
              >
                {error}
              </p>
            )}

            <button
              type="submit"
              disabled={busy || !email.trim() || !password}
              className="flex w-full items-center justify-center gap-2 rounded-lg bg-gradient-to-br from-brand-500 to-depot-700 px-4 py-2.5 text-sm font-medium text-white shadow-sm transition-opacity hover:opacity-95 disabled:opacity-45"
            >
              {busy && <Loader2 className="size-4 animate-spin" />}
              {busy ? 'Signing in…' : 'Sign in'}
            </button>
          </div>
        </form>

        <Link
          to="/"
          className="mt-5 flex items-center justify-center gap-1.5 text-xs text-muted-foreground transition-colors hover:text-foreground"
        >
          <ArrowLeft className="size-3.5" />
          Back to site
        </Link>
      </div>
    </div>
  )
}
