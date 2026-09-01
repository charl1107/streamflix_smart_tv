// Extension: AutoEmbed Provider
export const metadata = {
  id: "autoembed",
  name: "AutoEmbed Stream Provider",
  version: "1.0.0",
  description: "Fast multi-server movie and series embed resolver",
  author: "Community",
  types: ["movie", "tv"],
  enabled: true,
};

export async function extractStreams(tmdbId, type = "movie", season = 1, episode = 1) {
  // Returns clean fallback embed URL
  const embedUrl = type === "movie" 
    ? `https://autoembed.co/movie/tmdb/${tmdbId}`
    : `https://autoembed.co/tv/tmdb/${tmdbId}-${season}-${episode}`;

  return [{
    source: "AutoEmbed",
    server: "AutoEmbed Server",
    label: "Auto HD",
    isEmbed: true,
    url: embedUrl,
    headers: {},
  }];
}
