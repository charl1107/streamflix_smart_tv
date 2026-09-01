// TMDB API proxy routes
import { Hono } from "hono";

const app = new Hono();

// ── Helpers ────────────────────────────────────────────
async function tmdb(env, path, queryParams = {}) {
  const key = env.TMDB_API_KEY;
  const base = env.TMDB_BASE_URL || "https://api.themoviedb.org/3";

  if (!key || key.length < 4) {
    throw new Error("TMDB_API_KEY is not configured");
  }

  const url = new URL(`${base}${path}`);
  url.searchParams.set("api_key", key);

  for (const [k, v] of Object.entries(queryParams)) {
    if (v !== undefined && v !== null && v !== "") {
      url.searchParams.set(k, String(v));
    }
  }

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 10_000);

  try {
    const res = await fetch(url.toString(), {
      signal: controller.signal,
      headers: { "Accept-Language": "en-US" },
    });
    if (!res.ok) {
      const text = await res.text().catch(() => "");
      throw new Error(`TMDB ${res.status}: ${text.slice(0, 200)}`);
    }
    return res.json();
  } finally {
    clearTimeout(timeout);
  }
}

function getLanguage(c) {
  return c.req.query("language") || "en-US";
}

function releaseDateFields(type) {
  return type === "tv"
    ? { gte: "first_air_date.gte", lte: "first_air_date.lte", year: "first_air_date_year" }
    : { gte: "primary_release_date.gte", lte: "primary_release_date.lte", year: "primary_release_year" };
}

// ── Trending ───────────────────────────────────────────
app.get("/trending", async (c) => {
  try {
    const type = c.req.query("type") || "all";
    const window = c.req.query("window") || "week";
    return c.json(await tmdb(c.env, `/trending/${type}/${window}`, { language: getLanguage(c) }));
  } catch (err) {
    console.error("[tmdb/trending]", err.message);
    return c.json({ error: err.message, results: [] }, 503);
  }
});

// ── Search ─────────────────────────────────────────────
app.get("/search", async (c) => {
  try {
    const q = c.req.query("q");
    const type = c.req.query("type") || "multi";
    const page = c.req.query("page") || "1";
    if (!q) return c.json({ error: "q is required" }, 400);
    return c.json(await tmdb(c.env, `/search/${type}`, { query: q, page, language: getLanguage(c) }));
  } catch (err) {
    console.error("[tmdb/search]", err.message);
    return c.json({ error: err.message, results: [] }, 503);
  }
});

// ── Movie Details ──────────────────────────────────────
app.get("/movie/:id", async (c) => {
  try {
    const id = c.req.param("id");
    const append = c.req.query("append_to_response") || "credits,videos,similar,recommendations,images";
    const params = { append_to_response: append, language: getLanguage(c) };
    const includeImageLang = c.req.query("include_image_language");
    if (includeImageLang) params.include_image_language = includeImageLang;
    return c.json(await tmdb(c.env, `/movie/${id}`, params));
  } catch (err) {
    console.error("[tmdb/movie]", err.message);
    return c.json({ error: err.message }, 503);
  }
});

// ── TV Details ─────────────────────────────────────────
app.get("/tv/:id", async (c) => {
  try {
    const id = c.req.param("id");
    const append = c.req.query("append_to_response") || "credits,videos,similar,recommendations,images";
    const params = { append_to_response: append, language: getLanguage(c) };
    const includeImageLang = c.req.query("include_image_language");
    if (includeImageLang) params.include_image_language = includeImageLang;
    return c.json(await tmdb(c.env, `/tv/${id}`, params));
  } catch (err) {
    console.error("[tmdb/tv]", err.message);
    return c.json({ error: err.message }, 503);
  }
});

// ── TV Season ──────────────────────────────────────────
app.get("/tv/:id/season/:season", async (c) => {
  try {
    const { id, season } = c.req.param();
    return c.json(await tmdb(c.env, `/tv/${id}/season/${season}`, { language: getLanguage(c) }));
  } catch (err) {
    console.error("[tmdb/tv/season]", err.message);
    return c.json({ error: err.message }, 503);
  }
});

// ── Discover ───────────────────────────────────────────
app.get("/discover", async (c) => {
  try {
    const type = c.req.query("type") || "movie";
    const genre = c.req.query("genre");
    const year = c.req.query("year");
    const sortBy = c.req.query("sort_by") || "popularity.desc";
    const page = c.req.query("page") || "1";
    const fields = releaseDateFields(type);

    const params = { sort_by: sortBy, page, language: getLanguage(c) };
    if (genre) params.with_genres = genre;
    if (year) params[fields.year] = year;

    return c.json(await tmdb(c.env, `/discover/${type}`, params));
  } catch (err) {
    console.error("[tmdb/discover]", err.message);
    return c.json({ error: err.message, results: [] }, 503);
  }
});

// ── Genres ──────────────────────────────────────────────
app.get("/genres", async (c) => {
  try {
    const type = c.req.query("type") || "movie";
    return c.json(await tmdb(c.env, `/genre/${type}/list`, { language: getLanguage(c) }));
  } catch (err) {
    console.error("[tmdb/genres]", err.message);
    return c.json({ error: err.message, genres: [] }, 503);
  }
});

export default app;
