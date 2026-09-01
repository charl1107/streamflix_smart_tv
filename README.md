# StreamFlix TV 🎬📺

A modern, ad-free Smart TV streaming application built with **Flutter (Android TV)** and powered by a serverless **Cloudflare Workers (Hono)** edge backend.

---

## 🌟 Features

- **TV-First User Interface**: Optimized for 10-foot viewing with D-Pad spatial navigation and focus management.
- **Ad-Free M3U8 Streaming**: Cloudflare Edge proxy parses and rewrites HLS playlists to stream pure MPEG-TS video chunks without ad popups or redirects.
- **Multi-Source Extension Architecture**: Pluggable streaming providers (`Zoryva`, `AutoEmbed`, `MultiEmbed`) with automated failover.
- **Stremio Addon Protocol Compliant**: Compatible with standard Stremio ecosystem endpoints (`/api/stremio/manifest.json`, `/api/stremio/stream/...`).
- **Comprehensive Catalog**: Full support for Movies, TV Series, and Anime with episode selectors, search, and genre discovery via TMDB.
- **TV Remote Controls**: Direct key mapping for D-Pad Seek (Left/Right 10s), Volume (Up/Down), Play/Pause (Center/OK), and Back button navigation.

---

## 🏗️ Architecture

```
[Android TV App (Flutter)]
        │
        ▼ (Authenticated API calls)
[Cloudflare Worker Backend (Hono)]
   ├── /api/trending, /api/discover, /api/movie, /api/tv ──► TMDB API
   ├── /api/anime/* ──────────────────────────────────────► TMDB Animation & Discovery
   ├── /api/extensions ──────────────────────────────────► Pluggable Stream Extractors
   ├── /api/player ───────────────────────────────────────► Multi-Server Stream Resolver
   ├── /api/m3u8 ────────────────────────────────────────► Manifest Rewriter & Chunk Proxy
   └── /api/stremio/* ───────────────────────────────────► Stremio Addon Protocol
```

---

## 🚀 Getting Started

### 1. Backend (Cloudflare Workers)
```bash
cd backend
npm install
npx wrangler deploy
```

### 2. Frontend App (Flutter)
```bash
cd streamflix_tv_app
flutter pub get
flutter build apk --release
```

---

## 📄 License
This project is for educational and academic purposes only.
