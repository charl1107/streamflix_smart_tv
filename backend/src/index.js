// Backend entry point — Hono on Cloudflare Workers
import { Hono } from "hono";
import { cors } from "hono/cors";
import { logger } from "hono/logger";
import tmdbRoutes from "./routes/tmdb.js";
import animeRoutes from "./routes/anime.js";
import playerRoutes from "./routes/player.js";
import m3u8Routes from "./routes/m3u8.js";
import stremioRoutes from "./routes/stremio.js";

const app = new Hono();

// ── Logging ────────────────────────────────────────────
app.use("*", logger());

// ── Security Headers ───────────────────────────────────
app.use("*", async (c, next) => {
  c.header("X-Content-Type-Options", "nosniff");
  c.header("X-XSS-Protection", "1; mode=block");
  c.header("Referrer-Policy", "strict-origin-when-cross-origin");
  await next();
});

// ── CORS ───────────────────────────────────────────────
app.use("*", cors({
  origin: "*",
  allowMethods: ["GET", "OPTIONS"],
  allowHeaders: ["Content-Type"],
  maxAge: 86400,
}));

// ── Cache ──────────────────────────────────────────────
app.use("*", async (c, next) => {
  await next();
  if (c.req.method === "GET" && c.res.ok && !c.res.headers.get("Cache-Control")) {
    c.header("Cache-Control", "public, max-age=300, s-maxage=300");
  }
});

// ── Rate Limiting (simple per-IP) ──────────────────────
const rateLimits = new Map();
const WINDOW_MS = 60_000;
const MAX_REQUESTS = 120;

app.use("*", async (c, next) => {
  const ip = c.req.header("CF-Connecting-IP") || c.req.header("X-Forwarded-For") || "unknown";
  const now = Date.now();
  let entries = rateLimits.get(ip)?.filter((ts) => now - ts < WINDOW_MS) || [];

  if (entries.length >= MAX_REQUESTS) {
    c.header("Retry-After", "60");
    return c.json({ error: "RATE_LIMITED", message: "Too many requests." }, 429);
  }

  entries.push(now);
  rateLimits.set(ip, entries);

  // Periodic cleanup
  if (Math.random() < 0.01) {
    for (const [key, val] of rateLimits) {
      const filtered = val.filter((ts) => now - ts < WINDOW_MS);
      if (filtered.length === 0) rateLimits.delete(key);
      else rateLimits.set(key, filtered);
    }
  }

  await next();
});

// ── App Secret Authorization ───────────────────────────
app.use("/api/*", async (c, next) => {
  if (
    c.req.path === "/api/health" ||
    c.req.path === "/api/player" ||
    c.req.path === "/api/streams" ||
    c.req.path === "/api/subtitles" ||
    c.req.path.startsWith("/api/m3u8") ||
    c.req.path.startsWith("/api/stremio") ||
    c.req.path.startsWith("/api/extensions")
  ) {
    return next();
  }
  const appSecret = c.env.APP_SECRET;
  if (appSecret) {
    const clientSecret = c.req.header("X-App-Secret");
    if (!clientSecret || clientSecret !== appSecret) {
      return c.json({ error: "UNAUTHORIZED", message: "Invalid or missing app secret." }, 401);
    }
  }
  await next();
});

// ── Health Check ───────────────────────────────────────
app.get("/api/health", (c) => {
  return c.json({ status: "ok", timestamp: new Date().toISOString() });
});

// ── Routes ─────────────────────────────────────────────
app.route("/api", tmdbRoutes);
app.route("/api/anime", animeRoutes);
app.route("/api", playerRoutes);
app.route("/api", m3u8Routes);
app.route("/api", stremioRoutes);

// ── 404 ────────────────────────────────────────────────
app.notFound((c) => {
  return c.json({ error: "NOT_FOUND", message: `${c.req.method} ${c.req.path} not found` }, 404);
});

// ── Error Handler ──────────────────────────────────────
app.onError((err, c) => {
  console.error("[Error]", err.message, err.stack);
  c.header("Cache-Control", "no-store");
  return c.json({
    error: "INTERNAL_ERROR",
    message: c.env.NODE_ENV === "production" ? "An internal error occurred" : err.message,
  }, 500);
});

export default app;
