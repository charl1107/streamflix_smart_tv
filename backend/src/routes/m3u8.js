// M3U8 & TS Proxy — rewrites manifests and proxies segments with required headers
import { Hono } from "hono";

const app = new Hono();

function resolveUrl(relativeOrAbsolute, baseUrl) {
  try {
    return new URL(relativeOrAbsolute, baseUrl).toString();
  } catch (e) {
    return relativeOrAbsolute;
  }
}

app.get("/m3u8", async (c) => {
  const targetUrl = c.req.query("url");
  const referer = c.req.query("referer") || "";
  const origin = c.req.query("origin") || "";

  if (!targetUrl) {
    return c.text("Missing url parameter", 400);
  }

  const reqHeaders = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
    "Accept": "*/*",
  };
  if (referer) reqHeaders["Referer"] = referer;
  if (origin) reqHeaders["Origin"] = origin;

  try {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 12000);

    const res = await fetch(targetUrl, {
      headers: reqHeaders,
      signal: controller.signal,
    });
    clearTimeout(timeout);

    if (!res.ok) {
      return c.text(`Upstream error ${res.status}`, res.status);
    }

    const contentType = res.headers.get("content-type") || "";
    
    // If it's a binary/TS segment, stream it directly with CORS
    if (!contentType.includes("mpegurl") && !targetUrl.includes(".m3u8") && !targetUrl.includes("getm3u8")) {
      return new Response(res.body, {
        status: 200,
        headers: {
          "Content-Type": contentType || "video/MP2T",
          "Access-Control-Allow-Origin": "*",
          "Cache-Control": "public, max-age=86400",
        },
      });
    }

    // It's an M3U8 manifest: parse and rewrite URLs
    const text = await res.text();
    const currentWorkerBase = new URL(c.req.url).origin;
    const lines = text.split(/\r?\n/);
    const rewrittenLines = [];

    for (let i = 0; i < lines.length; i++) {
      const line = lines[i].trim();
      if (!line) {
        rewrittenLines.push("");
        continue;
      }

      // Check if line is an EXT tag with URI (e.g., #EXT-X-KEY, #EXT-X-MAP)
      if (line.startsWith("#")) {
        if (line.includes('URI="')) {
          const rewrittenTag = line.replace(/URI="([^"]+)"/, (match, uri) => {
            const absoluteUri = resolveUrl(uri, targetUrl);
            const proxyUri = `${currentWorkerBase}/api/m3u8?url=${encodeURIComponent(absoluteUri)}&referer=${encodeURIComponent(referer)}&origin=${encodeURIComponent(origin)}`;
            return `URI="${proxyUri}"`;
          });
          rewrittenLines.push(rewrittenTag);
        } else {
          rewrittenLines.push(line);
        }
        continue;
      }

      // This is a media segment or child playlist URI
      const absoluteUri = resolveUrl(line, targetUrl);
      
      // If the segment needs proxying, route through /api/m3u8, or proxy child playlists
      if (absoluteUri.includes(".m3u8") || absoluteUri.includes("/stream/") || absoluteUri.includes("/getm3u8")) {
        const proxyUri = `${currentWorkerBase}/api/m3u8?url=${encodeURIComponent(absoluteUri)}&referer=${encodeURIComponent(referer)}&origin=${encodeURIComponent(origin)}`;
        rewrittenLines.push(proxyUri);
      } else {
        // Direct TS segment: if it requires custom headers, proxy it too; otherwise direct URL works
        if (referer || origin) {
          const proxyUri = `${currentWorkerBase}/api/m3u8?url=${encodeURIComponent(absoluteUri)}&referer=${encodeURIComponent(referer)}&origin=${encodeURIComponent(origin)}`;
          rewrittenLines.push(proxyUri);
        } else {
          rewrittenLines.push(absoluteUri);
        }
      }
    }

    const rewrittenManifest = rewrittenLines.join("\n");

    return new Response(rewrittenManifest, {
      status: 200,
      headers: {
        "Content-Type": "application/vnd.apple.mpegurl",
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "*",
        "Cache-Control": "public, max-age=60",
      },
    });
  } catch (err) {
    console.error("[m3u8 proxy error]", err.message);
    return c.text(`Proxy error: ${err.message}`, 500);
  }
});

export default app;
