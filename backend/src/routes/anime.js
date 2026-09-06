// Anime catalogue and episode metadata from Anikoto, matching streamflix-cf.
// Anikoto IDs are provider IDs, so playback is resolved server-side per episode.
import { Hono } from "hono";

const app = new Hono();
const DEFAULT_ANIKOTO_URL = "https://anikotoapi.site";
const DEFAULT_JIKAN_URL = "https://api.jikan.moe/v4";
const DEFAULT_MEGAPLAY_URL = "https://megaplay.buzz";
const DEFAULT_VIDNEST_URL = "https://vidnest.fun";
const ANIKOTO_IMAGE_HOST = "cdn.anipixcdn.co";

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

function isAnikotoImageUrl(value) {
  try {
    const url = new URL(value);
    return url.protocol === "https:" && url.hostname === ANIKOTO_IMAGE_HOST;
  } catch {
    return false;
  }
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

async function mal(env, malId) {
  const url = new URL(`${baseUrl(env.JIKAN_API_URL, DEFAULT_JIKAN_URL)}/anime/${encodeURIComponent(malId)}/full`);
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 8_000);
  try {
    const response = await fetch(url, { headers: { Accept: "application/json" }, signal: controller.signal });
    if (!response.ok) throw new Error(`MAL metadata ${response.status}`);
    return response.json();
  } finally { clearTimeout(timeout); }
}

export function normalizeAnime(raw) {
  const titleObject = typeof raw?.title === "object" ? raw.title : null;
  const title = first(titleObject?.english, titleObject?.romaji, raw?.name, raw?.title, raw?.anime_title, "Untitled");
  const poster = image(first(raw?.poster, raw?.image, raw?.cover, raw?.thumbnail, raw?.coverImage));
  const malId = first(raw?.mal_id, raw?.malId, null);
  return {
    id: String(first(raw?.id, raw?.anime_id, raw?.animeId, raw?.series_id, raw?.slug, "")),
    title,
    poster_path: poster,
    // Anikoto's public catalogue calls the hero image `background_image`.
    // Reading it before the poster fallback restores full-width anime banners.
    backdrop_path: image(first(raw?.background_image, raw?.backgroundImage, raw?.banner, raw?.bannerImage, raw?.backdrop, raw?.poster_large)) || poster,
    overview: first(raw?.overview, raw?.description, raw?.synopsis, raw?.plot, ""),
    vote_average: Number(first(raw?.rating, raw?.score, raw?.averageScore, 0)) || 0,
    first_air_date: first(raw?.year, raw?.release_year, raw?.seasonYear, null),
    media_type: "anime",
    playback_type: "anime_provider",
    mal_id: malId ? Number(malId) : null,
    catalog_source: "anikoto",
    metadata_source: "anikoto",
    number_of_episodes: Number(first(raw?.episodes_count, raw?.episode_count, raw?.total_episodes, 0)) || null,
    status: raw?.status || null,
    genres: (raw?.genres || []).map((name) => typeof name === "string" ? { name } : name),
  };
}

function imageFromMal(raw) {
  return first(raw?.images?.jpg?.large_image_url, raw?.images?.webp?.large_image_url, raw?.images?.jpg?.image_url, null);
}

async function enrichWithMal(env, item) {
  if (!item.mal_id) return item;

  try {
    const payload = await mal(env, item.mal_id);
    const raw = payload?.data;
    if (!raw) return item;

    const malPoster = imageFromMal(raw);
    return {
      ...item,
      title: item.title || first(raw.title_english, raw.title, item.title),
      poster_path: item.poster_path || malPoster,
      // MAL-compatible metadata provides a poster rather than a dedicated
      // backdrop, so it is used only as the final visual fallback.
      backdrop_path: item.backdrop_path || malPoster,
      overview: item.overview || raw.synopsis || "",
      vote_average: item.vote_average || Number(raw.score || 0),
      first_air_date: item.first_air_date || raw.year || null,
      number_of_episodes: item.number_of_episodes || raw.episodes || null,
      status: item.status || raw.status || null,
      genres: item.genres?.length ? item.genres : (raw.genres || []).map(({ name }) => ({ name })),
      metadata_source: "mal",
    };
  } catch (error) {
    // MAL/Jikan availability must not block Anikoto browsing or playback.
    console.warn(`[anime/mal] metadata unavailable for ${item.mal_id}: ${error.message}`);
    return item;
  }
}

function listFrom(payload) { return Array.isArray(payload) ? payload : payload?.results || payload?.data || payload?.anime || []; }
function seriesFrom(payload) { return payload?.data?.anime || payload?.anime || payload?.data || payload; }
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
app.get("/image", async (c) => {
  const source = c.req.query("url");
  if (!source || !isAnikotoImageUrl(source)) {
    return c.json({ error: "Unsupported image source" }, 400);
  }

  try {
    const response = await fetch(source, {
      headers: { Accept: "image/avif,image/webp,image/*" },
      cf: { cacheTtl: 86_400, cacheEverything: true },
    });
    if (!response.ok || !response.body) {
      return c.json({ error: "Image is unavailable" }, 502);
    }

    return new Response(response.body, {
      headers: {
        "Content-Type": response.headers.get("Content-Type") || "image/jpeg",
        "Cache-Control": "public, max-age=86400, s-maxage=86400",
      },
    });
  } catch (error) {
    console.error("[anime/image]", error.message);
    return c.json({ error: "Image is unavailable" }, 502);
  }
});
app.get("/info/:id", async (c) => {
  try {
    const payload = await anikoto(c.env, `/series/${encodeURIComponent(c.req.param("id"))}`);
    const item = normalizeAnime(payload?.anime || payload?.data?.anime || payload?.data || payload);
    // Keep the detail/episode path fast. MAL/Jikan is optional metadata and can
    // be slow or rate-limited, so it must never delay the playable detail view.
    if (c.req.query("metadata") === "mal") {
      return c.json(await enrichWithMal(c.env, item));
    }
    return c.json(item);
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
    const series = seriesFrom(payload);
    const selected = episodeList(payload).map((item) => normalizeEpisode(item, id)).find((item) => item.number === episode);
    if (!selected) return c.json({ error: "Episode not found" }, 404);

    // Vidnest's /anime endpoint uses the AniList ID supplied by Anikoto. It is
    // distinct from Vidnest's /animepahe endpoint, which requires an
    // AnimePahe-specific ID that Anikoto does not expose.
    const aniListId = String(first(series?.ani_id, series?.aniId, ""));
    const vidnest = baseUrl(c.env.VIDNEST_EMBED_URL, DEFAULT_VIDNEST_URL);
    const vidnestUrl = /^[1-9]\d*$/.test(aniListId)
      ? `${vidnest}/anime/${aniListId}/${episode}/${audio}?server=lamda`
      : null;
    const directUrl = audio === "dub" ? selected.embedUrlDub || selected.embedUrlSub : selected.embedUrlSub || selected.embedUrlDub;
    const megaPlay = baseUrl(c.env.MEGAPLAY_EMBED_URL, DEFAULT_MEGAPLAY_URL);
    const megaPlayUrl = directUrl || (selected.episodeEmbedId ? `${megaPlay}/stream/s-2/${encodeURIComponent(selected.episodeEmbedId)}/${audio}` : null);
    const embedUrl = vidnestUrl || megaPlayUrl;
    if (!embedUrl) return c.json({ error: "Episode embed is unavailable" }, 503);
    return c.json({
      provider: vidnestUrl ? "Vidnest" : "Anikoto",
      source: vidnestUrl ? "anilist" : "anikoto",
      embedUrl,
      fallbackUrl: vidnestUrl ? megaPlayUrl : null,
      episode,
      audio,
    });
  } catch (error) { console.error("[anime/watch]", error.message); return c.json({ error: error.message }, 503); }
});

export default app;
