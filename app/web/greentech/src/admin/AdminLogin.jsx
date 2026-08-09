import { useState } from 'react'
import { Navigate, useNavigate } from 'react-router-dom'
import { Loader2, ShieldCheck } from 'lucide-react'
import { api } from '@/lib/api'
import { isAdmin, useAuth } from '@/lib/auth-context'

export default function AdminLogin() {
  const { login, user } = useAuth()
  const navigate = useNavigate()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
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
    <div className="min-h-screen bg-neutral-950 text-neutral-100 flex items-center justify-center px-4">
      <div className="w-full max-w-sm">
        <div className="mb-8 flex items-center gap-3">
          <span className="grid size-10 place-items-center rounded-xl bg-emerald-500/15 text-emerald-400">
            <ShieldCheck className="size-5" />
          </span>
          <div>
            <p className="font-semibold">GreenRoute Console</p>
            <p className="text-xs text-neutral-500">Municipal &amp; platform administration</p>
          </div>
        </div>

        <form onSubmit={submit} className="space-y-4">
          <div>
            <label className="mb-1.5 block text-xs font-medium text-neutral-400">Email</label>
            <input
              type="email"
              required
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="hmc.admin@GreenRoute.local"
              className="w-full rounded-lg border border-neutral-800 bg-neutral-900 px-3 py-2.5 text-sm outline-none transition focus:border-emerald-500/60"
            />
          </div>

          <div>
            <label className="mb-1.5 block text-xs font-medium text-neutral-400">Password</label>
            <input
              type="password"
              required
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="w-full rounded-lg border border-neutral-800 bg-neutral-900 px-3 py-2.5 text-sm outline-none transition focus:border-emerald-500/60"
            />
          </div>

          {error && (
            <p className="rounded-lg border border-red-500/30 bg-red-500/10 px-3 py-2 text-xs text-red-300">
              {error}
            </p>
          )}

          <button
            type="submit"
            disabled={busy}
            className="flex w-full items-center justify-center gap-2 rounded-lg bg-emerald-500 px-4 py-2.5 text-sm font-medium text-neutral-950 transition hover:bg-emerald-400 disabled:opacity-60"
          >
            {busy && <Loader2 className="size-4 animate-spin" />}
            Sign in
          </button>
        </form>

        <p className="mt-6 text-center text-[11px] text-neutral-600">
          API: {api.baseUrl}
        </p>
      </div>
    </div>
  )
}
