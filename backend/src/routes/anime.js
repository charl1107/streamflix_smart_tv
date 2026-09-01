// Anime routes — powered by TMDB Animation
import { Hono } from "hono";

const app = new Hono();

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

function normalizeTmdbAnime(data) {
  const results = Array.isArray(data?.results) ? data.results : [];
  return {
    results: results.map((item) => ({
      id: item.id,
      title: item.name || item.title || item.original_name || "Untitled",
      image: item.poster_path ? `https://image.tmdb.org/t/p/w500${item.poster_path}` : null,
      backdrop: item.backdrop_path ? `https://image.tmdb.org/t/p/w1280${item.backdrop_path}` : null,
      overview: item.overview || null,
      rating: Number((item.vote_average || 0).toFixed(1)),
      year: (item.first_air_date || item.release_date || "2026").substring(0, 4),
      type: "anime",
      genre_ids: item.genre_ids || [],
    })),
    total_results: data?.total_results || results.length,
    page: data?.page || 1,
    total_pages: data?.total_pages || 1,
  };
}

// ── Trending ───────────────────────────────────────────
app.get("/trending", async (c) => {
  try {
    const page = c.req.query("page") || "1";
    const data = await tmdb(c.env, "/discover/tv", {
      with_genres: "16",
      with_original_language: "ja",
      sort_by: "popularity.desc",
      page,
    });
    return c.json(normalizeTmdbAnime(data));
  } catch (err) {
    console.error("[anime/trending]", err.message);
    return c.json({ error: err.message, results: [] }, 500);
  }
});

// ── Popular ────────────────────────────────────────────
app.get("/popular", async (c) => {
  try {
    const page = c.req.query("page") || "1";
    const data = await tmdb(c.env, "/discover/tv", {
      with_genres: "16",
      sort_by: "vote_count.desc",
      page,
    });
    return c.json(normalizeTmdbAnime(data));
  } catch (err) {
    console.error("[anime/popular]", err.message);
    return c.json({ error: err.message, results: [] }, 500);
  }
});

// ── Recent ─────────────────────────────────────────────
app.get("/recent", async (c) => {
  try {
    const page = c.req.query("page") || "1";
    const data = await tmdb(c.env, "/discover/tv", {
      with_genres: "16",
      with_original_language: "ja",
      sort_by: "first_air_date.desc",
      "first_air_date.lte": new Date().toISOString().split("T")[0],
      page,
    });
    return c.json(normalizeTmdbAnime(data));
  } catch (err) {
    console.error("[anime/recent]", err.message);
    return c.json({ error: err.message, results: [] }, 500);
  }
});

// ── Search ─────────────────────────────────────────────
app.get("/search", async (c) => {
  try {
    const query = c.req.query("query") || c.req.query("q") || "";
    const page = c.req.query("page") || "1";
    if (!query) return c.json({ error: "query is required", results: [] }, 400);

    const data = await tmdb(c.env, "/search/tv", {
      query,
      page,
    });
    return c.json(normalizeTmdbAnime(data));
  } catch (err) {
    console.error("[anime/search]", err.message);
    return c.json({ error: err.message, results: [] }, 500);
  }
});

// ── Info ────────────────────────────────────────────────
app.get("/info/:id", async (c) => {
  try {
    const id = c.req.param("id");
    const data = await tmdb(c.env, `/tv/${id}`, {
      append_to_response: "credits,similar,recommendations",
    });

    return c.json({
      id: data.id,
      title: data.name || data.title || "Untitled",
      image: data.poster_path ? `https://image.tmdb.org/t/p/w500${data.poster_path}` : null,
      backdrop: data.backdrop_path ? `https://image.tmdb.org/t/p/w1280${data.backdrop_path}` : null,
      overview: data.overview || null,
      rating: Number((data.vote_average || 0).toFixed(1)),
      year: (data.first_air_date || "2026").substring(0, 4),
      status: data.status || null,
      totalEpisodes: data.number_of_episodes || null,
      numberOfSeasons: data.number_of_seasons || 1,
      seasons: data.seasons || [],
      genres: (data.genres || []).map((g) => g.name),
      type: "anime",
    });
  } catch (err) {
    console.error("[anime/info]", err.message);
    return c.json({ error: err.message }, 500);
  }
});

// ── Episodes ───────────────────────────────────────────
app.get("/episodes/:id", async (c) => {
  try {
    const id = c.req.param("id");
    const season = c.req.query("season") || "1";
    const data = await tmdb(c.env, `/tv/${id}/season/${season}`);

    const episodes = (data?.episodes || []).map((ep) => ({
      id: ep.id,
      number: ep.episode_number,
      title: ep.name || `Episode ${ep.episode_number}`,
      overview: ep.overview,
      stillPath: ep.still_path ? `https://image.tmdb.org/t/p/w500${ep.still_path}` : null,
    }));

    return c.json({
      animeId: id,
      season: Number(season),
      episodes,
      totalEpisodes: episodes.length,
    });
  } catch (err) {
    console.error("[anime/episodes]", err.message);
    return c.json({ error: err.message, episodes: [] }, 500);
  }
});

export default app;
