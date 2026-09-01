// Player route — powered by modular Extension Manager
import { Hono } from "hono";
import { listExtensions, resolveAllStreams } from "../extensions/index.js";

const app = new Hono();

// ── 1. Extensions API (For frontend settings / source info) ───
app.get("/extensions", (c) => {
  return c.json({
    status: "ok",
    extensions: listExtensions(),
  });
});

// ── 2. Player Route ───────────────────────────────────────────
app.get("/player", async (c) => {
  const type = (c.req.query("type") || "movie").toLowerCase();
  const id = c.req.query("id") || "";
  const season = Number(c.req.query("s") || c.req.query("season") || 1);
  const episode = Number(c.req.query("e") || c.req.query("episode") || 1);

  if (!id) {
    return c.html("<html><body style='background:#000;color:#fff;display:flex;align-items:center;justify-content:center;height:100vh;'><h2>Missing media ID</h2></body></html>", 400);
  }

  // 1. Resolve streams across all active extensions
  const { directStreams, backupEmbeds } = await resolveAllStreams(id, type, season, episode);

  const currentWorkerBase = new URL(c.req.url).origin;

  // Build proxied m3u8 stream list with source labels
  const proxiedStreams = directStreams.map((s, idx) => {
    const rawUrl = s.url;
    const ref = s.headers?.Referer || s.headers?.referer || "";
    const orig = s.headers?.Origin || s.headers?.origin || "";
    return {
      id: idx,
      source: s.source || "Extension",
      server: s.server || ("Server " + (idx + 1)),
      label: s.label || "HD",
      url: `${currentWorkerBase}/api/m3u8?url=${encodeURIComponent(rawUrl)}&referer=${encodeURIComponent(ref)}&origin=${encodeURIComponent(orig)}`,
    };
  });

  const streamsJson = JSON.stringify(proxiedStreams);
  const backupEmbedsJson = JSON.stringify(backupEmbeds);

  const html = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <title>StreamFlix TV Player</title>
  <script>
    // Strict Anti-Ad & Anti-Popup Shield
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
  <script src="https://cdn.jsdelivr.net/npm/hls.js@1.5.8/dist/hls.min.js"></script>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    html, body {
      width: 100vw;
      height: 100vh;
      background: #000;
      overflow: hidden;
      display: flex;
      align-items: center;
      justify-content: center;
      font-family: system-ui, -apple-system, sans-serif;
    }
    #video-player {
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
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 16px;
      color: #fff;
      font-size: 16px;
      z-index: 10;
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

    /* NuvioTV Extension & Server Selector Overlay */
    #server-btn {
      position: absolute;
      top: 24px;
      right: 24px;
      z-index: 50;
      background: rgba(20,20,30,0.85);
      backdrop-filter: blur(10px);
      border: 1px solid rgba(255,255,255,0.15);
      color: #fff;
      padding: 10px 18px;
      border-radius: 24px;
      font-size: 14px;
      font-weight: 600;
      cursor: pointer;
      display: flex;
      align-items: center;
      gap: 8px;
      transition: all 0.2s;
    }
    #server-btn:hover, #server-btn:focus {
      background: #3b82f6;
      border-color: #60a5fa;
      transform: scale(1.05);
      outline: none;
    }
    #server-modal {
      position: absolute;
      top: 0;
      left: 0;
      width: 100%;
      height: 100%;
      background: rgba(0,0,0,0.8);
      backdrop-filter: blur(12px);
      z-index: 100;
      display: none;
      align-items: center;
      justify-content: center;
    }
    .modal-card {
      background: #12131a;
      border: 1px solid rgba(255,255,255,0.1);
      border-radius: 16px;
      width: 460px;
      max-height: 80vh;
      display: flex;
      flex-direction: column;
      overflow: hidden;
      box-shadow: 0 20px 50px rgba(0,0,0,0.8);
    }
    .modal-header {
      padding: 18px 24px;
      border-bottom: 1px solid rgba(255,255,255,0.1);
      font-size: 18px;
      font-weight: 700;
      color: #fff;
      display: flex;
      justify-content: space-between;
      align-items: center;
    }
    .modal-close {
      background: transparent;
      border: 0;
      color: #94a3b8;
      font-size: 20px;
      cursor: pointer;
    }
    .server-list {
      padding: 12px;
      overflow-y: auto;
      display: flex;
      flex-direction: column;
      gap: 8px;
    }
    .server-item {
      padding: 14px 18px;
      border-radius: 10px;
      background: rgba(255,255,255,0.04);
      border: 1px solid transparent;
      color: #e2e8f0;
      font-size: 15px;
      display: flex;
      justify-content: space-between;
      align-items: center;
      cursor: pointer;
      transition: all 0.15s;
    }
    .server-item:hover, .server-item:focus {
      background: #2563eb;
      color: #fff;
      border-color: #60a5fa;
      outline: none;
      transform: translateX(4px);
    }
    .server-item.active {
      background: rgba(59,130,246,0.25);
      border-color: #3b82f6;
      color: #60a5fa;
      font-weight: 700;
    }
    .badges {
      display: flex;
      align-items: center;
      gap: 6px;
    }
    .badge {
      font-size: 11px;
      padding: 3px 7px;
      border-radius: 5px;
      background: rgba(255,255,255,0.1);
    }
    .badge-source {
      background: rgba(59,130,246,0.2);
      color: #93c5fd;
    }

    /* Hide ad and popup remnants */
    .adsbygoogle, .banner-ad, .popunder, div[id*="ad-"], div[class*="ad-"], #player-ad-overlay {
      display: none !important;
      opacity: 0 !important;
      pointer-events: none !important;
    }
  </style>
</head>
<body>
  <div id="loading">
    <div class="spinner"></div>
    <div id="loading-text">Loading Stream...</div>
  </div>

  <button id="server-btn" onclick="toggleServerModal()" tabindex="0">
    <span>📺 Extensions & Sources</span>
  </button>

  <div id="server-modal" onclick="if(event.target===this) toggleServerModal()">
    <div class="modal-card">
      <div class="modal-header">
        <span>Available Stream Extensions</span>
        <button class="modal-close" onclick="toggleServerModal()">✕</button>
      </div>
      <div class="server-list" id="server-list-container"></div>
    </div>
  </div>

  <video id="video-player" controls autoplay playsinline></video>

  <script>
    const video = document.getElementById('video-player');
    const loading = document.getElementById('loading');
    const streams = ${streamsJson};
    const backupEmbeds = ${backupEmbedsJson};
    let currentStreamIndex = 0;
    let embedIndex = 0;
    let hlsInstance = null;

    function hideLoading() {
      if (loading) loading.style.display = 'none';
    }

    function showLoading(text) {
      if (loading) {
        loading.style.display = 'flex';
        const txt = document.getElementById('loading-text');
        if (txt && text) txt.innerText = text;
      }
    }

    function renderServerList() {
      const container = document.getElementById('server-list-container');
      if (!container) return;
      container.innerHTML = '';

      streams.forEach((item, idx) => {
        const div = document.createElement('div');
        div.className = 'server-item' + (idx === currentStreamIndex ? ' active' : '');
        div.tabIndex = 0;
        div.innerHTML = '<span>' + item.server + '</span><div class="badges"><span class="badge badge-source">' + (item.source || 'Extension') + '</span><span class="badge">' + (item.label || 'HD') + '</span></div>';
        div.onclick = function() {
          selectStream(idx);
          toggleServerModal();
        };
        div.onkeydown = function(e) {
          if (e.key === 'Enter' || e.key === ' ') {
            selectStream(idx);
            toggleServerModal();
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
        renderServerList();
        const activeItem = modal.querySelector('.server-item.active') || modal.querySelector('.server-item');
        if (activeItem) activeItem.focus();
      } else {
        video.focus();
      }
    }

    function selectStream(index) {
      if (index >= 0 && index < streams.length) {
        currentStreamIndex = index;
        const item = streams[currentStreamIndex];
        showLoading('Connecting [' + item.source + '] ' + item.server + ' (' + item.label + ')...');
        playHls(item.url);
      }
    }

    function tryNextStream() {
      if (currentStreamIndex + 1 < streams.length) {
        currentStreamIndex++;
        selectStream(currentStreamIndex);
      } else {
        tryNextBackupEmbed();
      }
    }

    function playHls(m3u8Url) {
      if (hlsInstance) {
        hlsInstance.destroy();
        hlsInstance = null;
      }

      if (Hls.isSupported()) {
        hlsInstance = new Hls({
          enableWorker: true,
          lowLatencyMode: true,
          backBufferLength: 90,
          maxBufferSize: 60 * 1024 * 1024,
          maxBufferLength: 30
        });
        hlsInstance.loadSource(m3u8Url);
        hlsInstance.attachMedia(video);
        hlsInstance.on(Hls.Events.MANIFEST_PARSED, function() {
          hideLoading();
          video.play().catch(function(e) {});
        });
        hlsInstance.on(Hls.Events.ERROR, function(event, data) {
          if (data.fatal) {
            console.warn('HLS stream fatal error, trying next stream:', data.details);
            tryNextStream();
          }
        });
      } else if (video.canPlayType('application/vnd.apple.mpegurl')) {
        video.src = m3u8Url;
        video.onloadedmetadata = function() {
          hideLoading();
          video.play().catch(function() {});
        };
        video.onerror = function() {
          tryNextStream();
        };
      } else {
        tryNextBackupEmbed();
      }
    }

    function tryNextBackupEmbed() {
      if (embedIndex < backupEmbeds.length) {
        const embedUrl = backupEmbeds[embedIndex];
        embedIndex++;
        showLoading('Loading Backup Stream ' + embedIndex + '...');
        if (video) video.remove();
        const serverBtn = document.getElementById('server-btn');
        if (serverBtn) serverBtn.style.display = 'none';

        const oldIframe = document.querySelector('iframe');
        if (oldIframe) oldIframe.remove();

        const iframe = document.createElement('iframe');
        iframe.src = embedUrl;
        iframe.style = 'position:absolute;top:0;left:0;width:100%;height:100%;border:0;background:#000;';
        iframe.allow = 'autoplay; fullscreen; picture-in-picture; encrypted-media';
        iframe.setAttribute('sandbox', 'allow-scripts allow-same-origin allow-forms allow-presentation');
        iframe.allowFullscreen = true;
        iframe.onload = hideLoading;
        iframe.onerror = function() { tryNextBackupEmbed(); };
        document.body.appendChild(iframe);
      } else {
        showLoading('All streaming servers offline. Please try another title.');
      }
    }

    // TV Remote D-Pad controls (Left/Right seek, Up/Down volume/sources, Space/Enter play)
    window.addEventListener('keydown', function(e) {
      const modal = document.getElementById('server-modal');
      const isModalOpen = modal && modal.style.display === 'flex';

      if (e.key === 's' || e.key === 'S' || e.key === 'Menu' || e.key === 'ContextMenu') {
        toggleServerModal();
        e.preventDefault();
        return;
      }

      if (isModalOpen) {
        if (e.key === 'Escape' || e.key === 'Back' || e.key === 'Backspace') {
          toggleServerModal();
          e.preventDefault();
        }
        return;
      }

      if (!video) return;
      if (e.key === 'ArrowRight') { video.currentTime += 10; }
      else if (e.key === 'ArrowLeft') { video.currentTime -= 10; }
      else if (e.key === 'ArrowUp') { video.volume = Math.min(1, video.volume + 0.1); }
      else if (e.key === 'ArrowDown') { video.volume = Math.max(0, video.volume - 0.1); }
      else if (e.key === ' ' || e.key === 'Enter') {
        if (video.paused) video.play(); else video.pause();
      }
    });

    if (streams.length > 0) {
      selectStream(0);
      renderServerList();
    } else {
      tryNextBackupEmbed();
    }
  </script>
</body>
</html>`;

  c.header("Content-Type", "text/html; charset=utf-8");
  return c.html(html);
});

export default app;
