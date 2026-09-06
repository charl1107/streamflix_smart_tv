import { Hono } from "hono";
import { resolveAllStreams } from "../extensions/index.js";
import { buildVidnestUrl } from "./embed.js";

const app = new Hono();

const BLOCKED_REDIRECT_DOMAINS = [
  "doubleclick.net", "googlesyndication.com", "googleadservices.com", "googletagmanager.com",
  "googletagservices.com", "google-analytics.com", "analytics.google.com", "segment.io",
  "segment.com", "mixpanel.com", "amplitude.com", "hotjar.com", "sentry.io", "intercom.io",
  "scorecardresearch.com", "branch.io", "posthog.com", "facebook.net", "connect.facebook.net",
  "linkedin.com", "pendo.io", "optimizely.com", "fullstory.com", "clarity.ms", "matomo.org",
  "plausible.io", "newrelic.com", "datadoghq.com", "onesignal.com", "pixel.facebook.com",
  "ads.doubleclick.net", "stats.g.doubleclick.net", "www.google-analytics.com",
  "www.googletagmanager.com", "adservice.google.com", "pagead2.googlesyndication.com", "mopub.com",
  "adblock", "adblockplus", "adguard", "ublock", "ublockorigin", "adblocker", "adblockers",
  "easylist", "fanboy", "antiadblock", "adguarddns", "adblockanalytics",
  "obiitpudent.shop", "xl.obiitpudent.shop"
];

function isBlockedRedirectUrl(value) {
  if (!value) return true;
  try {
    const url = new URL(value);
    const host = url.hostname.toLowerCase();
    return BLOCKED_REDIRECT_DOMAINS.some((domain) => host.includes(domain) || value.toLowerCase().includes(domain));
  } catch {
    return true;
  }
}

function sanitizeEmbedUrl(rawUrl) {
  if (!rawUrl) return "";
  const trimmed = String(rawUrl).trim();
  if (!trimmed) return "";
  if (isBlockedRedirectUrl(trimmed)) {
    return "";
  }
  try {
    const url = new URL(trimmed);
    const host = url.hostname.toLowerCase();
    if (!host.includes("vidnest.fun") && !host.includes("streamflix") && !host.includes("cloudflare") && !host.includes("workers.dev")) {
      return "";
    }
    return url.toString();
  } catch {
    return "";
  }
}

function resolveSafeEmbedUrl(rawUrl, fallbackUrl) {
  const safeUrl = sanitizeEmbedUrl(rawUrl);
  return safeUrl || fallbackUrl;
}

// Supported Vidnest streaming servers
const VIDNEST_SERVERS = [
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

// ── 0. JSON Streams API ────────────────────────────────────────
app.get("/streams", async (c) => {
  const type = (c.req.query("type") || "movie").toLowerCase();
  const id = c.req.query("id") || "";
  const season = Number(c.req.query("s") || c.req.query("season") || 1);
  const episode = Number(c.req.query("e") || c.req.query("episode") || 1);

  if (!id) {
    return c.json({ error: "Missing media ID" }, 400);
  }

  const { directStreams, backupEmbeds } = await resolveAllStreams(id, type, season, episode);
  const currentWorkerBase = new URL(c.req.url).origin;

  const streams = directStreams.map((s, idx) => {
    const ref = s.headers?.Referer || s.headers?.referer || "";
    const orig = s.headers?.Origin || s.headers?.origin || "";
    return {
      id: idx,
      source: s.source || "Extension",
      server: s.server || `Server ${idx + 1}`,
      label: s.label || "HD",
      url: `${currentWorkerBase}/api/m3u8?url=${encodeURIComponent(s.url)}&referer=${encodeURIComponent(ref)}&origin=${encodeURIComponent(orig)}`,
    };
  });

  return c.json({ streams, backupEmbeds });
});

// ── 0b. Subtitle Tracks API (extract from M3U8 manifest) ──────
app.get("/subtitles", async (c) => {
  const m3u8Url = c.req.query("url");
  const referer = c.req.query("referer") || "";
  const origin = c.req.query("origin") || "";

  if (!m3u8Url) {
    return c.json({ error: "Missing url parameter" }, 400);
  }

  const reqHeaders = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
    "Accept": "*/*",
  };
  if (referer) reqHeaders["Referer"] = referer;
  if (origin) reqHeaders["Origin"] = origin;

  try {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 10000);
    const res = await fetch(m3u8Url, { headers: reqHeaders, signal: controller.signal });
    clearTimeout(timeout);

    if (!res.ok) {
      return c.json({ subtitles: [], error: `Upstream ${res.status}` });
    }

    const text = await res.text();
    const lines = text.split(/\r?\n/);
    const currentWorkerBase = new URL(c.req.url).origin;
    const subtitles = [];

    for (let i = 0; i < lines.length; i++) {
      const line = lines[i].trim();
      if (!line.startsWith("#EXT-X-MEDIA:")) continue;

      const typeMatch = line.match(/TYPE=([^,]+)/);
      if (!typeMatch || typeMatch[1].trim() !== "SUBTITLES") continue;

      const nameMatch = line.match(/NAME="([^"]+)"/);
      const langMatch = line.match(/LANGUAGE="([^"]+)"/);
      const uriMatch = line.match(/URI="([^"]+)"/);
      const defaultMatch = line.match(/DEFAULT=(YES|NO)/);
      const autoMatch = line.match(/AUTOSELECT=(YES|NO)/);

      if (!uriMatch) continue;

      let subUri = uriMatch[1];
      try {
        subUri = new URL(subUri, m3u8Url).toString();
      } catch (_) {}

      const proxyUrl = `${currentWorkerBase}/api/m3u8?url=${encodeURIComponent(subUri)}&referer=${encodeURIComponent(referer)}&origin=${encodeURIComponent(origin)}`;

      subtitles.push({
        name: nameMatch ? nameMatch[1] : "Unknown",
        language: langMatch ? langMatch[1] : "und",
        url: proxyUrl,
        isDefault: defaultMatch?.[1] === "YES",
        isAutoselect: autoMatch?.[1] === "YES",
      });
    }

    return c.json({ subtitles });
  } catch (err) {
    console.error("[subtitles error]", err.message);
    return c.json({ subtitles: [], error: err.message });
  }
});

// ── 1. Extensions API ──────────────────────────────────────────
app.get("/extensions", (c) => {
  return c.json({
    status: "ok",
    provider: "Vidnest Streaming Engine",
    servers: VIDNEST_SERVERS,
  });
});

// ── 2. Vidnest Player Route ────────────────────────────────────
app.get("/player", async (c) => {
  const type = (c.req.query("type") || "movie").toLowerCase();
  const id = c.req.query("id") || "";
  const season = c.req.query("s") || c.req.query("season") || "1";
  const episode = c.req.query("e") || c.req.query("episode") || "1";
  const server = c.req.query("server") || "lamda";
  const startAt = c.req.query("startAt") || c.req.query("progress") || "0";

  if (!id || !["movie", "tv", "anime"].includes(type)) {
    return c.html("<html><body style='background:#000;color:#fff;display:flex;align-items:center;justify-content:center;height:100vh;font-family:sans-serif;'><h2>Missing media ID</h2></body></html>", 400);
  }

  let embedUrl = "";
  try {
    embedUrl = buildVidnestUrl({
      type,
      id,
      season,
      episode,
      subOrDub: c.req.query("sub") || c.req.query("subOrDub") || "sub",
      server,
      startAt,
      isAnimePahe: c.req.query("pahe") === "true" || c.req.query("source") === "animepahe",
    });
  } catch (error) {
    return c.html(`<html><body style='background:#000;color:#fff;display:flex;align-items:center;justify-content:center;height:100vh;font-family:sans-serif;'><h2>${error.message}</h2></body></html>`, 400);
  }

  const fallbackUrl = "https://vidnest.fun/movie/324857?server=lamda";
  const safeEmbedUrl = sanitizeEmbedUrl(embedUrl);
  const finalEmbedUrl = resolveSafeEmbedUrl(safeEmbedUrl || embedUrl, fallbackUrl);
  const embedParams = new URL(finalEmbedUrl).searchParams;
  const activeServer = embedParams.get("server") || "lamda";
  const playbackStartAt = Number(embedParams.get("startAt") || 0);

  const serversJson = JSON.stringify(VIDNEST_SERVERS);

  const html = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <title>Vidnest TV Player</title>
  <script>
    // Strict Anti-Popup & Anti-Redirect Shields
    (function() {
      const noop = function() { return null; };
      window.open = noop;
      window.alert = noop;
      window.confirm = function() { return true; };
      window.prompt = noop;
      try {
        Object.defineProperty(window, 'open', { value: noop, writable: false });
      } catch(e) {}
    })();
  </script>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    html, body {
      width: 100vw;
      height: 100vh;
      background: #000;
      overflow: hidden;
      font-family: system-ui, -apple-system, sans-serif;
    }
    #vidnest-iframe {
      position: absolute;
      top: 0;
      left: 0;
      width: 100%;
      height: 100%;
      border: 0;
      outline: none;
      background: #000;
    }
    #loading {
      position: absolute;
      top: 0;
      left: 0;
      width: 100%;
      height: 100%;
      background: #000;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      gap: 16px;
      color: #fff;
      font-size: 16px;
      z-index: 10;
      pointer-events: none;
      transition: opacity 0.3s;
    }
    .spinner {
      width: 48px;
      height: 48px;
      border: 4px solid rgba(255,255,255,0.15);
      border-top-color: #3b82f6;
      border-radius: 50%;
      animation: spin 0.8s linear infinite;
    }
    @keyframes spin { to { transform: rotate(360deg); } }

    /* Top TV Server Switcher HUD */
    #server-badge-btn {
      position: absolute;
      top: 24px;
      right: 24px;
      z-index: 50;
      background: rgba(18, 20, 30, 0.85);
      backdrop-filter: blur(12px);
      border: 1.5px solid rgba(255, 255, 255, 0.2);
      color: #fff;
      padding: 10px 20px;
      border-radius: 24px;
      font-size: 14px;
      font-weight: 600;
      cursor: pointer;
      display: flex;
      align-items: center;
      gap: 10px;
      transition: all 0.2s;
    }
    #server-badge-btn:focus, #server-badge-btn:hover {
      background: #2563eb;
      border-color: #60a5fa;
      transform: scale(1.06);
      outline: none;
      box-shadow: 0 0 20px rgba(59, 130, 246, 0.6);
    }

    /* Modal Drawer for TV Server Selection */
    #server-modal {
      position: absolute;
      top: 0;
      left: 0;
      width: 100%;
      height: 100%;
      background: rgba(0, 0, 0, 0.85);
      backdrop-filter: blur(14px);
      z-index: 100;
      display: none;
      align-items: center;
      justify-content: center;
    }
    .modal-card {
      background: #111420;
      border: 1.5px solid rgba(255, 255, 255, 0.15);
      border-radius: 20px;
      width: 640px;
      max-height: 85vh;
      display: flex;
      flex-direction: column;
      overflow: hidden;
      box-shadow: 0 25px 60px rgba(0, 0, 0, 0.9);
      padding: 24px;
    }
    .modal-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 8px;
    }
    .modal-title {
      color: #fff;
      font-size: 20px;
      font-weight: 700;
    }
    .modal-hint {
      color: rgba(255,255,255,0.6);
      font-size: 13px;
      margin-bottom: 20px;
    }
    .server-grid {
      display: grid;
      grid-template-columns: repeat(3, 1fr);
      gap: 12px;
      overflow-y: auto;
    }
    .server-card {
      padding: 14px;
      background: rgba(255, 255, 255, 0.05);
      border: 1.5px solid rgba(255, 255, 255, 0.1);
      border-radius: 12px;
      color: #e2e8f0;
      cursor: pointer;
      display: flex;
      flex-direction: column;
      gap: 4px;
      transition: all 0.15s;
    }
    .server-card:focus, .server-card:hover {
      background: #2563eb;
      border-color: #60a5fa;
      outline: none;
      transform: scale(1.04);
      box-shadow: 0 0 15px rgba(59, 130, 246, 0.5);
    }
    .server-card.active {
      border-color: #10b981;
      background: rgba(16, 185, 129, 0.2);
    }
    .server-card-top {
      display: flex;
      justify-content: space-between;
      align-items: center;
      font-weight: 700;
      font-size: 15px;
    }
    .server-badge {
      font-size: 10px;
      padding: 2px 6px;
      border-radius: 4px;
      background: rgba(255,255,255,0.15);
    }
    .server-card-desc {
      font-size: 11px;
      color: rgba(255, 255, 255, 0.6);
    }
  </style>
</head>
<body>
  <button id="server-badge-btn" onclick="toggleServerModal()" tabindex="0">
    <span>📺 Switch Server (▲)</span>
  </button>

  <div id="server-modal" onclick="if(event.target===this) toggleServerModal()">
    <div class="modal-card">
      <div class="modal-header">
        <span class="modal-title">Select Vidnest Streaming Server</span>
      </div>
      <div class="modal-hint">Navigate with TV Remote D-Pad • Press OK to switch</div>
      <div class="server-grid" id="server-grid"></div>
    </div>
  </div>

  <!-- Sandboxed Vidnest Embed Iframe (Official Vidnest Player) -->
  <iframe
    id="vidnest-iframe"
    src="${finalEmbedUrl}"
    frameBorder="0"
    scrolling="no"
    allow="autoplay; fullscreen; picture-in-picture; encrypted-media"
    referrerpolicy="origin"
    allowfullscreen>
  </iframe>

  <script>
    const iframe = document.getElementById('vidnest-iframe');
    const servers = ${serversJson};
    let currentServer = "${activeServer}";
    let currentSeconds = ${playbackStartAt};

    // Listen to video progress events from iframe if dispatched
    window.addEventListener('message', function(e) {
      if (e.data && typeof e.data.currentTime === 'number') {
        currentSeconds = Math.floor(e.data.currentTime);
      }
    });

    function renderServers() {
      const container = document.getElementById('server-grid');
      if (!container) return;
      container.innerHTML = '';

      servers.forEach((s, idx) => {
        const div = document.createElement('div');
        div.className = 'server-card' + (s.id.toLowerCase() === currentServer.toLowerCase() ? ' active' : '');
        div.tabIndex = 0;
        div.innerHTML = [
          '<div class="server-card-top">',
          '<span>' + s.name + '</span>',
          '<span class="server-badge">' + s.badge + '</span>',
          '</div>',
          '<div class="server-card-desc">' + s.desc + '</div>'
        ].join('');
        div.onclick = () => switchServer(s.id);
        div.onkeydown = (e) => {
          if (e.key === 'Enter' || e.key === ' ') {
            switchServer(s.id);
          }
        };
        container.appendChild(div);
      });
    }

    function toggleServerModal() {
      const modal = document.getElementById('server-modal');
      if (!modal) return;
      const isOpen = modal.style.display === 'flex';
      modal.style.display = isOpen ? 'none' : 'flex';
      if (!isOpen) {
        renderServers();
        const activeCard = modal.querySelector('.server-card.active') || modal.querySelector('.server-card');
        if (activeCard) activeCard.focus();
      }
    }

    function switchServer(serverId) {
      currentServer = serverId;
      toggleServerModal();

      const mediaType = "${type}";
      const mediaId = "${id}";
      let nextUrl = "";
      if (mediaType === "tv") {
        nextUrl = "https://vidnest.fun/tv/" + mediaId + "/${season}/${episode}?server=" + serverId;
      } else if (mediaType === "anime") {
        nextUrl = "https://vidnest.fun/anime/" + mediaId + "/${episode}/sub?server=" + serverId;
      } else {
        nextUrl = "https://vidnest.fun/movie/" + mediaId + "?server=" + serverId;
      }

      if (currentSeconds > 0) {
        nextUrl += "&startAt=" + currentSeconds;
      }

      const allowed = /^https:\/\/[A-Za-z0-9.-]*vidnest\.fun\//i.test(nextUrl) || /^https:\/\/.*streamflix/i.test(nextUrl) || /^https:\/\/.*workers\.dev/i.test(nextUrl);
      if (!allowed) {
        console.warn('[Player Redirect Guard] Blocked unsafe redirect target:', nextUrl);
        return;
      }

      iframe.src = nextUrl;
    }

    // Remote D-Pad Navigation Listener
    window.addEventListener('keydown', function(e) {
      const modal = document.getElementById('server-modal');
      const isModalOpen = modal && modal.style.display === 'flex';

      if (e.key === 'ArrowUp' || e.key === 'Menu' || e.key === 's' || e.key === 'S') {
        if (!isModalOpen) {
          toggleServerModal();
          e.preventDefault();
        }
      } else if (e.key === 'Escape' || e.key === 'Back' || e.key === 'Backspace') {
        if (isModalOpen) {
          toggleServerModal();
          e.preventDefault();
        }
      }
    });

    renderServers();
  </script>
</body>
</html>`;

  c.header("Content-Type", "text/html; charset=utf-8");
  c.header("Cache-Control", "no-store, no-cache, must-revalidate, max-age=0");
  c.header("Pragma", "no-cache");
  c.header("Expires", "0");
  return c.html(html);
});

export default app;
