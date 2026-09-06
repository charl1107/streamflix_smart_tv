// Anime catalogue and episode metadata from Anikoto, matching streamflix-cf.
// Anikoto IDs are provider IDs, so playback is resolved server-side per episode.
import { Hono } from "hono";

const app = new Hono();
const DEFAULT_ANIKOTO_URL = "https://anikotoapi.site";
const DEFAULT_MEGAPLAY_URL = "https://megaplay.buzz";

function baseUrl(value, fallback) { return String(value || fallback).replace(/\/$/, ""); }
function first(...values) { return values.find((value) => value !== undefined && value !== null && value !== ""); }
function image(value) {
  if (typeof value === "string") return value;
  return value ? first(value.extraLarge, value.large, value.medium, value.url, value.src) || null : null;
}
function positiveInteger(value, name) {
  if (!/^[1-9]\d*$/.test(String(value || ""))) throw new Error(`${name} must be a positive integer`);
  return Number(value);
}

async function anikoto(env, path, query = {}) {
  const url = new URL(`${baseUrl(env.ANIKOTO_API_URL, DEFAULT_ANIKOTO_URL)}${path}`);
  Object.entries(query).forEach(([key, value]) => { if (value !== undefined && value !== null) url.searchParams.set(key, String(value)); });
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 15_000);
  try {
    const response = await fetch(url, { headers: { Accept: "application/json" }, signal: controller.signal });
    const payload = await response.json().catch(() => ({}));
    if (!response.ok) throw new Error(`Anikoto ${response.status}`);
    return payload;
  } finally { clearTimeout(timeout); }
}

function normalizeAnime(raw) {
  const titleObject = typeof raw?.title === "object" ? raw.title : null;
  const title = first(titleObject?.english, titleObject?.romaji, raw?.name, raw?.title, raw?.anime_title, "Untitled");
  const poster = image(first(raw?.poster, raw?.image, raw?.cover, raw?.thumbnail, raw?.coverImage));
  return {
    id: String(first(raw?.id, raw?.anime_id, raw?.animeId, raw?.series_id, raw?.slug, "")),
    title,
    poster_path: poster,
    backdrop_path: image(first(raw?.banner, raw?.bannerImage, raw?.backdrop, raw?.poster_large)) || poster,
    overview: first(raw?.overview, raw?.description, raw?.synopsis, raw?.plot, ""),
    vote_average: Number(first(raw?.rating, raw?.score, raw?.averageScore, 0)) || 0,
    first_air_date: first(raw?.year, raw?.release_year, raw?.seasonYear, null),
    media_type: "anime",
    playback_type: "anime_provider",
    number_of_episodes: Number(first(raw?.episodes_count, raw?.episode_count, raw?.total_episodes, 0)) || null,
    status: raw?.status || null,
    genres: (raw?.genres || []).map((name) => typeof name === "string" ? { name } : name),
  };
}

function listFrom(payload) { return Array.isArray(payload) ? payload : payload?.results || payload?.data || payload?.anime || []; }
function episodeList(payload) { return payload?.episodes || payload?.data?.episodes || payload?.anime?.episodes || payload?.data?.anime?.episodes || []; }
function normalizeEpisode(raw, animeId) {
  const number = Number(first(raw?.number, raw?.episode, raw?.episode_number, raw?.ep, 0));
  const embedId = first(raw?.episode_embed_id, raw?.embed_id, raw?.embedId, raw?.server_id, raw?.id);
  return {
    id: String(embedId || `${animeId}-${number}`), number,
    title: first(raw?.title, raw?.name, `Episode ${number}`),
    episodeEmbedId: embedId ? String(embedId) : null,
    embedUrlSub: first(raw?.embed_url?.sub, raw?.embedUrl?.sub, raw?.sub, raw?.sub_url, null),
    embedUrlDub: first(raw?.embed_url?.dub, raw?.embedUrl?.dub, raw?.dub, raw?.dub_url, null),
  };
}

async function recent(c, offset = 0) {
  const page = positiveInteger(c.req.query("page") || "1", "page") + offset;
  const payload = await anikoto(c.env, "/recent-anime", { page, per_page: 20 });
  const results = listFrom(payload).map(normalizeAnime).filter((item) => item.id);
  return c.json({ results, page, total_pages: payload?.total_pages || 1, total_results: payload?.total || results.length });
}
function unavailable(scope, error, c) { console.error(`[anime/${scope}]`, error.message); return c.json({ error: error.message, results: [] }, 503); }

app.get("/trending", async (c) => { try { return await recent(c); } catch (error) { return unavailable("trending", error, c); } });
app.get("/popular", async (c) => { try { return await recent(c, 1); } catch (error) { return unavailable("popular", error, c); } });
app.get("/recent", async (c) => { try { return await recent(c); } catch (error) { return unavailable("recent", error, c); } });
app.get("/search", async (c) => {
  try {
    const query = c.req.query("q") || c.req.query("query");
    if (!query?.trim()) return c.json({ error: "query is required", results: [] }, 400);
    const payload = await anikoto(c.env, "/recent-anime", { page: 1, per_page: 200 });
    const term = query.toLowerCase().trim();
    const results = listFrom(payload).map(normalizeAnime).filter((item) => item.title.toLowerCase().includes(term));
    return c.json({ results, page: 1, total_pages: 1, total_results: results.length });
  } catch (error) { return unavailable("search", error, c); }
});
app.get("/info/:id", async (c) => {
  try {
    const payload = await anikoto(c.env, `/series/${encodeURIComponent(c.req.param("id"))}`);
    return c.json(normalizeAnime(payload?.anime || payload?.data?.anime || payload?.data || payload));
  } catch (error) { return unavailable("info", error, c); }
});
app.get("/episodes/:id", async (c) => {
  try {
    const id = c.req.param("id");
    const payload = await anikoto(c.env, `/series/${encodeURIComponent(id)}`);
    const episodes = episodeList(payload).map((item) => normalizeEpisode(item, id)).filter((item) => item.number > 0);
    return c.json({ episodes, total: episodes.length });
  } catch (error) { console.error("[anime/episodes]", error.message); return c.json({ error: error.message, episodes: [] }, 503); }
});
app.get("/watch", async (c) => {
  try {
    const id = c.req.query("id");
    if (!id) return c.json({ error: "Anime ID is required" }, 400);
    const episode = positiveInteger(c.req.query("episode") || "1", "episode");
    const audio = (c.req.query("audio") || "sub").toLowerCase() === "dub" ? "dub" : "sub";
    const payload = await anikoto(c.env, `/series/${encodeURIComponent(id)}`);
    const selected = episodeList(payload).map((item) => normalizeEpisode(item, id)).find((item) => item.number === episode);
    if (!selected) return c.json({ error: "Episode not found" }, 404);
    const directUrl = audio === "dub" ? selected.embedUrlDub || selected.embedUrlSub : selected.embedUrlSub || selected.embedUrlDub;
    const megaPlay = baseUrl(c.env.MEGAPLAY_EMBED_URL, DEFAULT_MEGAPLAY_URL);
    const embedUrl = directUrl || (selected.episodeEmbedId ? `${megaPlay}/stream/s-2/${encodeURIComponent(selected.episodeEmbedId)}/${audio}` : null);
    if (!embedUrl) return c.json({ error: "Episode embed is unavailable" }, 503);
    return c.json({ provider: "Anikoto", embedUrl, episode, audio });
  } catch (error) { console.error("[anime/watch]", error.message); return c.json({ error: error.message }, 503); }
});

export default app;
