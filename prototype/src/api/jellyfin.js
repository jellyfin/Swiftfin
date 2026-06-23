// Thin Jellyfin REST client for the PoC. In dev, BASE='/jf' is proxied to the
// server by Vite (see vite.config.js), so we avoid CORS entirely.

const TOKEN = import.meta.env.VITE_JELLYFIN_TOKEN
const USER = import.meta.env.VITE_JELLYFIN_USER
const BASE = import.meta.env.VITE_JELLYFIN_BASE || '/jf'

async function jget(path) {
  const res = await fetch(`${BASE}${path}`, { headers: { 'X-Emby-Token': TOKEN } })
  if (!res.ok) throw new Error(`${res.status} on ${path}`)
  return res.json()
}

export function imageUrl(itemId, type = 'Primary') {
  return `${BASE}/Items/${itemId}/Images/${type}?api_key=${TOKEN}`
}

// The 7 pinned "group tiles" (and any other Jellyfin favorites) — these are the
// collections we flagged IsFavorite, ordered by our ForcedSortName scheme.
export async function getGroupTiles() {
  const d = await jget(
    `/Users/${USER}/Items?IncludeItemTypes=BoxSet&Recursive=true&IsFavorite=true&Fields=SortName,Overview`
  )
  return (d.Items || []).sort((a, b) => (a.SortName || '').localeCompare(b.SortName || ''))
}

export async function getCollectionItems(parentId) {
  const d = await jget(`/Users/${USER}/Items?ParentId=${parentId}&Fields=Overview`)
  return d.Items || []
}

export async function getRecent(limit = 20) {
  const d = await jget(
    `/Users/${USER}/Items?IncludeItemTypes=Movie&Recursive=true&SortBy=DateCreated&SortOrder=Descending&Limit=${limit}&Fields=Overview,ProductionYear`
  )
  return d.Items || []
}

export async function getRandom(limit = 20) {
  const d = await jget(
    `/Users/${USER}/Items?IncludeItemTypes=Movie&Recursive=true&SortBy=Random&Limit=${limit}&Fields=Overview,ProductionYear`
  )
  return d.Items || []
}
