// backend/src/routes/embed.js
// Vidnest-Only Embed API based on Official Vidnest Embed Documentation
import { Hono } from "hono";

const app = new Hono();

// Vidnest Official Supported Servers
export const VIDNEST_SERVERS = [
  { id: "lamda", name: "Lamda", badge: "Fast", desc: "Primary High-Speed Mirror" },
  { id: "primesrc", name: "PrimeSrc", badge: "1080p", desc: "Multi-Bitrate Stream" },
  { id: "gama", name: "Gama", badge: "HD", desc: "Ultra-Low Latency" },
  { id: "alfa", name: "Alfa", badge: "Stable", desc: "Global Edge Mirror" },
  { id: "beta", name: "Beta", badge: "HD", desc: "High Compatibility" },
  { id: "sigma", name: "Sigma", badge: "Mirror", desc: "Multi-Source Backup" },
  { id: "catflix", name: "Catflix", badge: "Fast", desc: "Fast Stream Mirror" },
  { id: "hexa", name: "Hexa", badge: "Backup", desc: "Alternative Server 1" },
  { id: "delta", name: "Delta", badge: "Backup", desc: "Alternative Server 2" },
];

const CONTROL_PARAMS = [
  "servericon", "topcaption", "topsettings", "centerseekbackward",
  "centerplay", "centerseekforward", "timeslider", "mute", "volume",
  "timegroup", "bottomcaption", "bottomsettings", "pip", "cast",
  "fullscreen", "prevepisode", "nextepisode"
];

const SERVER_IDS = new Set(VIDNEST_SERVERS.map(({ id }) => id));

function positiveInteger(value, name) {
  const normalized = String(value ?? "").trim();
  if (!/^[1-9]\d*$/.test(normalized)) {
    throw new Error(`${name} must be a positive integer`);
  }
  return normalized;
}

function optionalSeconds(value) {
  const normalized = Number(value || 0);
  if (!Number.isFinite(normalized) || normalized < 0) {
    throw new Error("startAt must be zero or a positive number");
  }
  return Math.floor(normalized);
}

export function buildVidnestUrl({
  type = "movie",
  id,
  season = 1,
  episode = 1,
  subOrDub = "sub",
  server = "lamda",
  startAt = 0,
  controls = {},
  isAnimePahe = false,
}) {
  const cleanType = String(type).toLowerCase();
  if (!["movie", "tv", "anime"].includes(cleanType)) {
    throw new Error("type must be movie, tv, or anime");
  }
  const cleanId = positiveInteger(id, cleanType === "anime" ? "AniList ID" : "TMDB ID");
  const cleanSeason = positiveInteger(season, "season");
  const cleanEpisode = positiveInteger(episode, "episode");
  const cleanStartAt = optionalSeconds(startAt);
  const cleanServer = server && SERVER_IDS.has(server) ? server : "lamda";
  const cleanAudio = String(subOrDub || "sub").toLowerCase();
  if (!/^[a-z0-9-]+$/.test(cleanAudio)) {
    throw new Error("subOrDub contains unsupported characters");
  }

  let path = "";

  if (cleanType === "tv") {
    path = `https://vidnest.fun/tv/${cleanId}/${cleanSeason}/${cleanEpisode}`;
  } else if (cleanType === "anime") {
    if (isAnimePahe) {
      path = `https://vidnest.fun/animepahe/${cleanId}/${cleanEpisode}/${cleanAudio}`;
    } else {
      path = `https://vidnest.fun/anime/${cleanId}/${cleanEpisode}/${cleanAudio}`;
    }
  } else {
    path = `https://vidnest.fun/movie/${cleanId}`;
  }

  const query = new URLSearchParams();
  query.set("server", cleanServer);
  if (cleanStartAt > 0) {
    query.set("startAt", String(cleanStartAt));
  }

  // Handle control hiding parameters
  for (const ctrl of CONTROL_PARAMS) {
    if (controls[ctrl] !== undefined) {
      query.set(ctrl, String(controls[ctrl]));
    }
  }

  const qs = query.toString();
  return qs ? `${path}?${qs}` : path;
}

export function buildIframeHtml(embedUrl) {
  return `<iframe src="${embedUrl}" frameBorder="0" scrolling="no" allowFullScreen></iframe>`;
}

// GET /api/embed/servers
app.get("/servers", (c) => {
  return c.json({
    provider: "Vidnest",
    servers: VIDNEST_SERVERS,
  });
});

// GET /api/embed/:type/:id?season=&episode=&sub=&server=&startAt=
app.get("/:type/:id", async (c) => {
  try {
    const { type, id } = c.req.param();
    const season = c.req.query("season") || c.req.query("s") || "1";
    const episode = c.req.query("episode") || c.req.query("e") || "1";
    const subOrDub = c.req.query("sub") || c.req.query("subOrDub") || "sub";
    const server = c.req.query("server") || "lamda";
    const startAt = c.req.query("startAt") || c.req.query("progress") || "0";
    const isAnimePahe = c.req.query("pahe") === "true" || c.req.query("source") === "animepahe";

    if (!["movie", "tv", "anime"].includes(type.toLowerCase())) {
      return c.json({ error: "type must be movie, tv, or anime" }, 400);
    }

    // Extract any control hide query params
    const controls = {};
    for (const ctrl of CONTROL_PARAMS) {
      const val = c.req.query(ctrl);
      if (val !== undefined) {
        controls[ctrl] = val;
      }
    }

    const embedUrl = buildVidnestUrl({
      type,
      id,
      season,
      episode,
      subOrDub,
      server,
      startAt,
      controls,
      isAnimePahe,
    });

    const iframeCode = buildIframeHtml(embedUrl);

    c.header("Cache-Control", "no-store, no-cache, must-revalidate");
    return c.json({
      provider: "Vidnest",
      type,
      id,
      server,
      embedUrl,
      iframeCode,
      servers: VIDNEST_SERVERS,
      ...(type === "tv" && { season, episode }),
      ...(type === "anime" && { episode, subOrDub, isAnimePahe }),
    });
  } catch (err) {
    console.error("[embed error]", err.message);
    return c.json({ error: err.message }, 400);
  }
});

export default app;
