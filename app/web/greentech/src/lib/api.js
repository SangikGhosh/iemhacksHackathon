const BASE = import.meta.env.VITE_API_BASE_URL || 'http://localhost:8080'
const TOKEN_KEY = 'greentech.token'
const USER_KEY = 'greentech.user'

export const getToken = () => localStorage.getItem(TOKEN_KEY)
export const getStoredUser = () => {
  try {
    return JSON.parse(localStorage.getItem(USER_KEY) || 'null')
  } catch {
    return null
  }
}

export const storeSession = (token, user) => {
  localStorage.setItem(TOKEN_KEY, token)
  localStorage.setItem(USER_KEY, JSON.stringify(user))
}

export const clearSession = () => {
  localStorage.removeItem(TOKEN_KEY)
  localStorage.removeItem(USER_KEY)
}

export class ApiError extends Error {
  constructor(message, status) {
    super(message)
    this.status = status
  }
}

// Only ngrok needs this header, and sending it everywhere adds it to the CORS
// preflight — which the API rejects unless it is in its allowed-headers list.
const needsNgrokHeader = /ngrok(-free)?\.(app|io|dev)/.test(BASE)

async function request(path, { method = 'GET', body, auth = true } = {}) {
  const headers = {}
  if (needsNgrokHeader) headers['ngrok-skip-browser-warning'] = '1'
  if (body !== undefined) headers['Content-Type'] = 'application/json'

  const token = getToken()
  if (auth && token) headers.Authorization = `Bearer ${token}`

  let response
  try {
    response = await fetch(`${BASE}${path}`, {
      method,
      headers,
      body: body === undefined ? undefined : JSON.stringify(body),
    })
  } catch {
    throw new ApiError(`Cannot reach the API at ${BASE}. Is the backend running?`, 0)
  }

  if (response.status === 204) return null

  const text = await response.text()
  const data = text ? JSON.parse(text) : null

  if (!response.ok) {
    if (response.status === 401) clearSession()
    throw new ApiError(data?.error || data?.detail || response.statusText, response.status)
  }

  return data
}

export const api = {
  baseUrl: BASE,
  login: (email, password) =>
    request('/auth/login', { method: 'POST', body: { email, password }, auth: false }),
  me: () => request('/auth/me'),
  health: () => request('/health', { auth: false }),

  overview: () => request('/api/v1/admin/overview'),
  users: ({ role, search, page = 0, size = 50 } = {}) => {
    const q = new URLSearchParams({ page, size })
    if (role) q.set('role', role)
    if (search) q.set('search', search)
    return request(`/api/v1/admin/users?${q}`)
  },
  createUser: (payload) => request('/api/v1/admin/users', { method: 'POST', body: payload }),
  updateUser: (id, payload) => request(`/api/v1/admin/users/${id}`, { method: 'PATCH', body: payload }),

  systemHealth: () => request('/api/v1/admin/system-health'),
  points: () => request('/api/v1/admin/collection-points'),
  createPoint: (payload) =>
    request('/api/v1/admin/collection-points', { method: 'POST', body: payload }),
  updatePoint: (id, payload) =>
    request(`/api/v1/admin/collection-points/${id}`, { method: 'PATCH', body: payload }),
  deletePoint: (id) => request(`/api/v1/admin/collection-points/${id}`, { method: 'DELETE' }),

  municipalities: () => request('/api/v1/admin/municipalities'),
  createMunicipality: (payload) =>
    request('/api/v1/admin/municipalities', { method: 'POST', body: payload }),
  updateMunicipality: (id, payload) =>
    request(`/api/v1/admin/municipalities/${id}`, { method: 'PATCH', body: payload }),

  leaderboard: (limit = 10) => request(`/api/v1/leaderboard?limit=${limit}`, { auth: false }),
  listings: () => request('/api/v1/listings'),
  wasteTypes: () => request('/api/v1/collection-points/municipalities', { auth: false }),
}
