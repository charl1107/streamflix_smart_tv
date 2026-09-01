// Extension: MultiEmbed Provider
export const metadata = {
  id: "multiembed",
  name: "MultiEmbed Core",
  version: "1.0.0",
  description: "Reliable fallback aggregator for international and classic movies",
  author: "Community",
  types: ["movie", "tv"],
  enabled: true,
};

export async function extractStreams(tmdbId, type = "movie", season = 1, episode = 1) {
  const embedUrl = type === "movie"
    ? `https://multiembed.mov/?video_id=${tmdbId}&tmdb=1`
    : `https://multiembed.mov/?video_id=${tmdbId}&tmdb=1&s=${season}&e=${episode}`;

  return [{
    source: "MultiEmbed",
    server: "MultiEmbed VIP",
    label: "VIP Multi",
    isEmbed: true,
    url: embedUrl,
    headers: {},
  }];
}
