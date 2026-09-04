// backend/src/routes/embed.js
// Multi-provider Embed API — Vidnest, Zoryva, VidSrc, AutoEmbed, 2Embed
import { Hono } from "hono";

const app = new Hono();

const SOURCES = [
  {
    id: "vidnest",
    name: "Vidnest",
    badge: "Recommended",
    movie: (id, server = "lamda") => `https://vidnest.fun/movie/${id}?server=${encodeURIComponent(server)}`,
    tv: (id, s, e, server = "lamda") => `https://vidnest.fun/tv/${id}/${s}/${e}?server=${encodeURIComponent(server)}`,
    anime: (id, s, e, server = "lamda") => `https://vidnest.fun/anime/${id}/${e}/sub?server=${encodeURIComponent(server)}`,
  },
  {
    id: "zoryva",
    name: "Zoryva",
    badge: "Fast",
    movie: (id) => `https://zoryva.me/embedded/movie/${id}`,
    tv: (id, s, e) => `https://zoryva.me/embedded/tv/${id}/${s}/${e}`,
    anime: (id, s, e) => `https://zoryva.me/embedded/tv/${id}/${s}/${e}`,
  },
  {
    id: "vidsrc",
    name: "VidSrc",
    badge: "HD",
    movie: (id) => `https://vidsrc.mov/embed/movie/${id}`,
    tv: (id, s, e) => `https://vidsrc.mov/embed/tv/${id}/${s}/${e}`,
    anime: (id, s, e) => `https://vidsrc.mov/embed/tv/${id}/${s}/${e}`,
  },
  {
    id: "autoembed",
    name: "AutoEmbed",
    badge: "Multi",
    movie: (id) => `https://player.autoembed.cc/embed/movie/${id}`,
    tv: (id, s, e) => `https://player.autoembed.cc/embed/tv/${id}/${s}/${e}`,
    anime: (id, s, e) => `https://player.autoembed.cc/embed/tv/${id}/${s}/${e}`,
  },
  {
    id: "2embed",
    name: "2Embed",
    badge: "Backup",
    movie: (id) => `https://www.2embed.cc/embed/${id}`,
    tv: (id, s, e) => `https://www.2embed.cc/embedtv/${id}&s=${s}&e=${e}`,
    anime: (id, s, e) => `https://www.2embed.cc/embedtv/${id}&s=${s}&e=${e}`,
  },
];

// GET /api/embed/sources
app.get("/sources", (c) => {
  return c.json({
    sources: SOURCES.map((s) => ({
      id: s.id,
      name: s.name,
      badge: s.badge,
    })),
  });
});

// GET /api/embed/:type/:id?season=&episode=&provider=&server=
app.get("/:type/:id", async (c) => {
  try {
    const { type, id } = c.req.param();
    const season = c.req.query("season") || c.req.query("s") || "1";
    const episode = c.req.query("episode") || c.req.query("e") || "1";
    const provider = c.req.query("provider") || "vidnest";
    const server = c.req.query("server") || "lamda";

    if (!["movie", "tv", "anime"].includes(type)) {
      return c.json({ error: "type must be movie, tv, or anime" }, 400);
    }

    if (!id) {
      return c.json({ error: "Valid ID required" }, 400);
    }

    const sources = SOURCES.map((src) => {
      let url = "";
      if (type === "movie") {
        url = src.id === "vidnest" ? src.movie(id, server) : src.movie(id);
      } else if (type === "tv") {
        url = src.id === "vidnest" ? src.tv(id, season, episode, server) : src.tv(id, season, episode);
      } else if (type === "anime") {
        url = src.id === "vidnest" ? src.anime(id, season, episode, server) : src.anime(id, season, episode);
      }
      return {
        id: src.id,
        name: src.name,
        badge: src.badge,
        url,
      };
    });

    const selected = sources.find(
      (s) => s.id.toLowerCase() === provider.toLowerCase() || s.name.toLowerCase() === provider.toLowerCase()
    ) || sources[0];

    c.header("Cache-Control", "public, max-age=300, s-maxage=300");
    return c.json({
      embedUrl: selected.url,
      provider: selected.name,
      providerId: selected.id,
      sources,
      type,
      id,
      ...(type !== "movie" && { season: parseInt(season, 10), episode: parseInt(episode, 10) }),
    });
  } catch (err) {
    console.error("[embed error]", err.message);
    return c.json({ error: err.message }, 500);
  }
});

export default app;
