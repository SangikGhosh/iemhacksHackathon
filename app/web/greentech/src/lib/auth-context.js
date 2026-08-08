import { createContext, useContext } from 'react'

export const AuthContext = createContext(null)

export function useAuth() {
  const context = useContext(AuthContext)
  if (!context) throw new Error('useAuth must be used inside AuthProvider')
  return context
}

export const isAdmin = (user) =>
  user?.role === 'MUNICIPAL_ADMIN' || user?.role === 'SUPER_ADMIN'
