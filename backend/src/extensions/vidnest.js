// Extension: VidNest Provider
export const metadata = {
  id: "vidnest",
  name: "VidNest Stream Provider",
  version: "1.0.0",
  description: "Fast multi-source movie and series embed resolver",
  author: "Community",
  types: ["movie", "tv"],
  enabled: true,
};

export async function extractStreams(tmdbId, type = "movie", season = 1, episode = 1) {
  const embedUrl = type === "movie"
    ? `https://vidnest.fun/movie/${tmdbId}`
    : `https://vidnest.fun/tv/${tmdbId}/${season}/${episode}`;

  return [{
    source: "VidNest",
    server: "VidNest Server",
    label: "Vid HD",
    isEmbed: true,
    url: embedUrl,
    headers: {},
  }];
}
