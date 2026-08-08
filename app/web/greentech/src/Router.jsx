import { Suspense, lazy } from 'react'
import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom'

import Landing from './App.jsx'
import ScrollToTop from './components/ScrollToTop.jsx'
import AdminLogin from './admin/AdminLogin.jsx'
import { AuthProvider } from './lib/auth.jsx'
import { isAdmin, useAuth } from './lib/auth-context.js'

const SuperAdmin = lazy(() => import('./admin/SuperAdmin.jsx'))
const MunicipalAdmin = lazy(() => import('./admin/MunicipalAdmin.jsx'))
const NotFound = lazy(() => import('./pages/NotFound.jsx'))

function RouteFallback() {
  return (
    <div className="flex min-h-svh items-center justify-center bg-neutral-100">
      <div className="flex flex-col items-center gap-4">
        <img
          src="/logo-mark.png"
          alt=""
          width={40}
          height={40}
          className="h-10 w-10 animate-pulse object-contain"
        />
        <p className="text-sm text-muted-foreground">Loading console…</p>
      </div>
    </div>
  )
}

function RequireRole({ roles, children }) {
  const { user, isAuthenticated } = useAuth()

  if (!isAuthenticated || !isAdmin(user)) {
    return <Navigate to="/admin/login" replace />
  }

  if (!roles.includes(user.role)) {
    return <Navigate to={user.role === 'SUPER_ADMIN' ? '/admin/super' : '/admin/municipal'} replace />
  }

  return children
}

export default function Router() {
  return (
    <BrowserRouter>
      <AuthProvider>
        <ScrollToTop />
        <Suspense fallback={<RouteFallback />}>
          <Routes>
            <Route path="/" element={<Landing />} />
            <Route path="/admin" element={<Navigate to="/admin/login" replace />} />
            <Route path="/admin/login" element={<AdminLogin />} />
            <Route
              path="/admin/super"
              element={
                <RequireRole roles={['SUPER_ADMIN']}>
                  <SuperAdmin />
                </RequireRole>
              }
            />
            <Route
              path="/admin/municipal"
              element={
                <RequireRole roles={['MUNICIPAL_ADMIN', 'SUPER_ADMIN']}>
                  <MunicipalAdmin />
                </RequireRole>
              }
            />
            <Route path="*" element={<NotFound />} />
          </Routes>
        </Suspense>
      </AuthProvider>
    </BrowserRouter>
  )
}
