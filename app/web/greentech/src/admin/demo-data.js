/**
 * Sample data for the two admin consoles.
 *
 * None of this is fetched — the consoles are presentation-only in this build.
 * Shapes deliberately mirror the real API responses documented in
 * service/api-java/README.md so that wiring them up later is a swap, not a
 * rewrite. Values are plausible rather than measured, and the consoles say so.
 */

const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
const scanSeries = [412, 468, 441, 523, 587, 702, 664, 498, 545, 571, 634, 689, 771, 728]
const pickupSeries = [128, 151, 143, 168, 191, 236, 219, 162, 178, 187, 209, 228, 262, 244]

export const trendData = days.map((day, i) => ({
  day: `${day} ${i < 7 ? 1 : 2}`,
  scans: scanSeries[i],
  pickups: pickupSeries[i],
}))

export const trendSeries = [
  { key: 'scans', label: 'Scans' },
  { key: 'pickups', label: 'Pickups' },
]

const spark = (arr) => arr.map((v) => ({ v }))

export const superStats = [
  { label: 'Total scans', value: 48219, delta: 12.4, deltaLabel: 'vs last week', spark: spark([380, 412, 468, 441, 523, 587, 702]) },
  { label: 'Active citizens', value: 6480, delta: 8.1, deltaLabel: 'vs last week', spark: spark([5980, 6050, 6130, 6210, 6290, 6380, 6480]) },
  { label: 'Waste diverted', value: 31.6, decimals: 1, suffix: ' t', delta: 15.2, deltaLabel: 'vs last week', spark: spark([22, 24, 25.5, 27, 28.4, 30.1, 31.6]) },
  { label: 'Points issued', value: 284310, delta: -3.2, deltaLabel: 'vs last week', spark: spark([31000, 30200, 29400, 28800, 28100, 27600, 27200]) },
]

export const services = [
  {
    name: 'api-java',
    detail: 'Spring Boot 3.5 · :8080',
    status: 'HEALTHY',
    uptime: 99.98,
    latency: '84 ms',
    note: 'System of record — auth, pickups, routing',
  },
  {
    name: 'api-python',
    detail: 'FastAPI + YOLOv8m · :8000',
    status: 'HEALTHY',
    uptime: 99.71,
    latency: '1.81 s',
    note: 'Warm inference. Cold start adds ~1.6 s',
  },
  {
    name: 'PostgreSQL',
    detail: 'Hikari pool 20',
    status: 'HEALTHY',
    uptime: 100,
    latency: '6 ms',
    note: '4 tables, indexed on (user_id, created_at)',
  },
  {
    name: 'Mapbox',
    detail: 'Matrix + Directions',
    status: 'DEGRADED',
    uptime: 97.4,
    latency: '412 ms',
    note: 'Rate limited twice today — falls back to haversine order',
  },
  {
    name: 'Cloudinary',
    detail: 'GreenRoute/detections',
    status: 'HEALTHY',
    uptime: 99.95,
    latency: '240 ms',
    note: 'Upload runs in parallel with inference',
  },
  {
    name: 'Resend',
    detail: 'OTP, welcome, sign-in alerts',
    status: 'HEALTHY',
    uptime: 99.89,
    latency: '310 ms',
    note: 'OTP failure returns 502 rather than a false "sent"',
  },
]

export const municipalityPerformance = [
  { name: 'Howrah MC', value: 18420, points: 100, collectors: 34, diverted: 14.2 },
  { name: 'Bidhannagar MC', value: 9760, points: 30, collectors: 18, diverted: 8.1 },
  { name: 'Barrackpore', value: 7180, points: 25, collectors: 12, diverted: 6.4 },
  { name: 'Uluberia', value: 2410, points: 0, collectors: 6, diverted: 2.9 },
]

export const binTotals = [
  { bin: 'BLUE', stream: 'Dry', value: 18240 },
  { bin: 'GREEN', stream: 'Wet', value: 7860 },
  { bin: 'GREY', stream: 'Dry', value: 3910 },
  { bin: 'RED', stream: 'Hazardous', value: 1590 },
]

export const roleDistribution = [
  { role: 'CITIZEN', count: 6480, selfAssign: true },
  { role: 'COLLECTOR', count: 70, selfAssign: true },
  { role: 'RECYCLER', count: 23, selfAssign: true },
  { role: 'MUNICIPAL_ADMIN', count: 4, selfAssign: false },
  { role: 'SUPER_ADMIN', count: 2, selfAssign: false },
]

export const recentUsers = [
  { id: 'u1', name: 'Ananya Ghosh', email: 'ananya.g@example.com', role: 'CITIZEN', municipality: 'Howrah MC', points: 1240, joined: '2 h ago' },
  { id: 'u2', name: 'Rahul Das', email: 'rahul.das@example.com', role: 'COLLECTOR', municipality: 'Howrah MC', points: 3180, joined: '5 h ago' },
  { id: 'u3', name: 'Priya Sen', email: 'priya.sen@example.com', role: 'CITIZEN', municipality: 'Bidhannagar MC', points: 640, joined: '9 h ago' },
  { id: 'u4', name: 'Imran Khan', email: 'imran.k@example.com', role: 'RECYCLER', municipality: 'Barrackpore', points: 0, joined: '1 d ago' },
  { id: 'u5', name: 'Sourav Mitra', email: 's.mitra@example.com', role: 'COLLECTOR', municipality: 'Barrackpore', points: 2260, joined: '1 d ago' },
  { id: 'u6', name: 'Debjani Roy', email: 'debjani.r@example.com', role: 'MUNICIPAL_ADMIN', municipality: 'Uluberia', points: 0, joined: '2 d ago' },
]

export const modelInfo = {
  modelId: 'waste-detector-v1',
  name: 'YOLOv8 Medium',
  weightsVersion: '2026.08.08',
  parameters: '25,902,640',
  dataset: 'COCO · 80 classes',
  imageSize: 1280,
  confidence: 0.3,
  iou: 0.5,
  maxDet: 300,
  warm: '1.81 s',
  cold: '3.4 s',
}

/* -------------------------------------------------------------------------- */
/* Municipal console                                                           */
/* -------------------------------------------------------------------------- */

export const municipalStats = [
  { label: 'Open pickups', value: 47, delta: 6.2, deltaLabel: 'vs yesterday', spark: spark([28, 33, 36, 41, 39, 44, 47]) },
  { label: 'Collectors on shift', value: 22, delta: 0, deltaLabel: 'of 34 registered', spark: spark([20, 21, 22, 22, 21, 22, 22]) },
  { label: 'Diverted today', value: 2.14, decimals: 2, suffix: ' t', delta: 9.8, deltaLabel: 'vs yesterday', spark: spark([1.4, 1.6, 1.7, 1.85, 1.9, 2.0, 2.14]) },
  { label: 'Avg. response', value: 34, suffix: ' min', delta: -11.5, deltaLabel: 'request to accept', spark: spark([44, 42, 41, 39, 38, 36, 34]) },
]

export const livePickups = [
  { id: 'PK-4821', citizen: 'Ananya Ghosh', ward: 'Ward 12 · Shibpur', mode: 'DOORSTEP', status: 'REQUESTED', material: 'PET Bottle ×13', weight: 0.39, offer: 9.75, collector: null, age: '4 min' },
  { id: 'PK-4820', citizen: 'Sujoy Pal', ward: 'Ward 8 · Salkia', mode: 'DROP_OFF', status: 'ACCEPTED', material: 'Cardboard ×6', weight: 1.8, offer: 14.4, collector: 'Rahul Das', age: '18 min' },
  { id: 'PK-4819', citizen: 'Meera Bose', ward: 'Ward 21 · Bally', mode: 'DOORSTEP', status: 'ACCEPTED', material: 'E-Waste ×1', weight: 1.5, offer: 90.0, collector: 'Sourav Mitra', age: '26 min' },
  { id: 'PK-4818', citizen: 'Arjun Nair', ward: 'Ward 3 · Liluah', mode: 'DROP_OFF', status: 'COMPLETED', material: 'Aluminium Can ×22', weight: 0.33, offer: 39.6, collector: 'Rahul Das', age: '52 min' },
  { id: 'PK-4817', citizen: 'Kavya Iyer', ward: 'Ward 15 · Belur', mode: 'DOORSTEP', status: 'REQUESTED', material: 'Paper ×9', weight: 1.8, offer: 21.6, collector: null, age: '1 h' },
  { id: 'PK-4816', citizen: 'Tanmay Ghosh', ward: 'Ward 7 · Santragachi', mode: 'DOORSTEP', status: 'CANCELLED', material: 'Mixed Waste ×4', weight: 0.4, offer: 0, collector: null, age: '1 h' },
  { id: 'PK-4815', citizen: 'Riya Sarkar', ward: 'Ward 12 · Shibpur', mode: 'DROP_OFF', status: 'COMPLETED', material: 'Glass Bottle ×5', weight: 2.0, offer: 4.0, collector: 'Nabin Roy', age: '2 h' },
]

export const collectors = [
  { id: 'c1', name: 'Rahul Das', vehicle: 'WB-11-4821', status: 'ACTIVE', load: 62, capacity: 80, stops: 6, route: '33.1 km', completed: 14 },
  { id: 'c2', name: 'Sourav Mitra', vehicle: 'WB-11-9034', status: 'ACTIVE', load: 74, capacity: 80, stops: 8, route: '41.7 km', completed: 11 },
  { id: 'c3', name: 'Nabin Roy', vehicle: 'WB-11-2277', status: 'FULL', load: 80, capacity: 80, stops: 9, route: '28.4 km', completed: 17 },
  { id: 'c4', name: 'Farhan Ali', vehicle: 'WB-11-6612', status: 'ACTIVE', load: 31, capacity: 80, stops: 3, route: '19.2 km', completed: 8 },
  { id: 'c5', name: 'Bikash Halder', vehicle: 'WB-11-3390', status: 'IDLE', load: 0, capacity: 80, stops: 0, route: '—', completed: 6 },
]

export const collectionPoints = [
  { code: 'CP-HMC-012', name: 'Shibpur Bazaar', ward: 'Ward 12', type: 'MRF', status: 'OK', fill: 42 },
  { code: 'CP-HMC-026', name: 'Salkia Crossing', ward: 'Ward 8', type: 'Bin cluster', status: 'FULL', fill: 96 },
  { code: 'CP-HMC-029', name: 'Bally Halt', ward: 'Ward 21', type: 'Bin cluster', status: 'OK', fill: 58 },
  { code: 'CP-HMC-041', name: 'Liluah Depot Gate', ward: 'Ward 3', type: 'MRF', status: 'OK', fill: 24 },
  { code: 'CP-HMC-055', name: 'Belur Math Road', ward: 'Ward 15', type: 'Bin cluster', status: 'OK', fill: 71 },
  { code: 'CP-HMC-063', name: 'Santragachi Yard', ward: 'Ward 7', type: 'Transfer', status: 'OK', fill: 37 },
]

export const wardPerformance = [
  { name: 'Ward 12', value: 4820 },
  { name: 'Ward 8', value: 3910 },
  { name: 'Ward 21', value: 3240 },
  { name: 'Ward 15', value: 2680 },
  { name: 'Ward 3', value: 2110 },
  { name: 'Ward 7', value: 1490 },
]

export const municipalBins = [
  { bin: 'BLUE', stream: 'Dry', value: 6420 },
  { bin: 'GREEN', stream: 'Wet', value: 2980 },
  { bin: 'GREY', stream: 'Dry', value: 1340 },
  { bin: 'RED', stream: 'Hazardous', value: 520 },
]

export const alerts = [
  { id: 'a1', severity: 'high', title: 'CP-HMC-026 at 96% capacity', body: 'Salkia Crossing has not been serviced in 26 hours. Four drop-offs are queued against it.', time: '12 min ago' },
  { id: 'a2', severity: 'medium', title: 'Mapbox rate limit hit twice', body: 'Nearest-point search fell back to straight-line ordering for 8 minutes this morning.', time: '2 h ago' },
  { id: 'a3', severity: 'low', title: '3 pickups unclaimed past 1 hour', body: 'Ward 15 and Ward 7 have no collector on shift within the service radius.', time: '3 h ago' },
]
