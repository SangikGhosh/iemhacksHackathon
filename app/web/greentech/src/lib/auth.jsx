import { useCallback, useMemo, useState } from 'react'
import { api, clearSession, getStoredUser, getToken, storeSession } from './api'
import { AuthContext } from './auth-context'

export function AuthProvider({ children }) {
  const [user, setUser] = useState(() => getStoredUser())

  const login = useCallback(async (email, password) => {
    const result = await api.login(email, password)
    storeSession(result.accessToken, result.user)
    setUser(result.user)
    return result.user
  }, [])

  const logout = useCallback(() => {
    clearSession()
    setUser(null)
  }, [])

  const value = useMemo(
    () => ({ user, login, logout, isAuthenticated: Boolean(user && getToken()) }),
    [user, login, logout],
  )

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}
