// Stremio Addon Protocol Route — provides standard /manifest.json and /stream endpoints
import { Hono } from "hono";

const app = new Hono();

// ── 1. Addon Manifest ───────────────────────────────────
app.get("/stremio/manifest.json", (c) => {
  const manifest = {
    id: "org.streamflix.tv",
    version: "1.0.0",
    name: "StreamFlix TV Engine",
    description: "Multi-server 1080p HLS streaming engine with ad-free m3u8 proxy",
    resources: ["stream"],
    types: ["movie", "series", "anime"],
    catalogs: [],
    idPrefixes: ["tt", "tmdb:"],
  };

  c.header("Content-Type", "application/json");
  c.header("Access-Control-Allow-Origin", "*");
  return c.json(manifest);
});

// ── 2. Stream Resolver (Stremio Standard) ───────────────
app.get("/stremio/stream/:type/:id", async (c) => {
  const type = c.req.param("type");
  let rawId = (c.req.param("id") || "").replace(/\.json$/, "");

  // Format: tmdb:1078605 or tmdb:1396:1:1 or raw ID
  let tmdbId = rawId;
  let season = 1;
  let episode = 1;

  if (rawId.includes(":")) {
    const parts = rawId.split(":");
    if (parts[0] === "tmdb") {
      tmdbId = parts[1];
      if (parts.length >= 4) {
        season = Number(parts[2]);
        episode = Number(parts[3]);
      }
    } else {
      tmdbId = parts[0];
      if (parts.length >= 3) {
        season = Number(parts[1]);
        episode = Number(parts[2]);
      }
    }
  }

  const mediaType = (type === "series" || type === "tv") ? "tv" : type === "anime" ? "anime" : "movie";

  try {
    const streamApiUrl = `https://zoryva.me/api/stream?type=${mediaType}&tmdbId=${tmdbId}&season=${season}&episode=${episode}`;
    const res = await fetch(streamApiUrl, {
      headers: {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
        "Accept": "application/json",
      },
    });

    const data = await res.json();
    const rawStreams = data?.ok && Array.isArray(data.streams) ? data.streams : [];
    const currentWorkerBase = new URL(c.req.url).origin;

    const streams = rawStreams.map((s, index) => {
      const ref = s.headers?.Referer || s.headers?.referer || "";
      const orig = s.headers?.Origin || s.headers?.origin || "";
      const proxiedUrl = `${currentWorkerBase}/api/m3u8?url=${encodeURIComponent(s.url)}&referer=${encodeURIComponent(ref)}&origin=${encodeURIComponent(orig)}`;

      return {
        name: `StreamFlix ${s.label || '1080p'}`,
        title: `${s.server || 'Server ' + (index + 1)} • ${s.label || 'HD'} (No Ads)`,
        url: proxiedUrl,
      };
    });

    c.header("Content-Type", "application/json");
    c.header("Access-Control-Allow-Origin", "*");
    return c.json({ streams });
  } catch (err) {
    console.error("[stremio stream error]", err.message);
    return c.json({ streams: [] });
  }
});

export default app;
