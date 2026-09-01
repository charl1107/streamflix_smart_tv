// Extension: Zoryva Multi-Server Extractor
export const metadata = {
  id: "zoryva",
  name: "Zoryva Stream Engine",
  version: "1.2.0",
  description: "Aggregates 7-17 multi-server 1080p/720p HLS streams",
  author: "StreamFlix Core",
  types: ["movie", "tv", "anime"],
  enabled: true,
};

export async function extractStreams(tmdbId, type = "movie", season = 1, episode = 1) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 12000);
  try {
    const url = `https://zoryva.me/api/stream?type=${type}&tmdbId=${tmdbId}&season=${season}&episode=${episode}`;
    const res = await fetch(url, {
      headers: {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
        "Accept": "application/json",
      },
      signal: controller.signal,
    });
    if (!res.ok) return [];
    const data = await res.json();
    if (data?.ok && Array.isArray(data.streams)) {
      return data.streams.map((s, i) => ({
        source: "Zoryva",
        server: s.server || ("Server " + (i + 1)),
        label: s.label || "HD",
        url: s.url,
        headers: s.headers || {},
      }));
    }
    return [];
  } catch (e) {
    return [];
  } finally {
    clearTimeout(timeout);
  }
}
