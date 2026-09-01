// Extension Manager & Stream Pool Orchestrator
import * as zoryva from "./zoryva.js";
import * as autoembed from "./autoembed.js";
import * as multiembed from "./multiembed.js";
import * as vidnest from "./vidnest.js";

const extensions = [zoryva, autoembed, multiembed, vidnest];

export function listExtensions() {
  return extensions.map(e => e.metadata);
}

export async function resolveAllStreams(tmdbId, type = "movie", season = 1, episode = 1) {
  const activeExtensions = extensions.filter(e => e.metadata.enabled && e.metadata.types.includes(type));

  const streamPromises = activeExtensions.map(async (ext) => {
    try {
      let streams = await ext.extractStreams(tmdbId, type, season, episode);
      // If anime query yields 0 streams, fallback query as tv
      if (streams.length === 0 && type === "anime") {
        streams = await ext.extractStreams(tmdbId, "tv", season, episode);
      }
      return streams;
    } catch (e) {
      console.error(`[Extension: ${ext.metadata.id} error]`, e.message);
      return [];
    }
  });

  const results = await Promise.allSettled(streamPromises);
  const allStreams = [];
  const embedFallbacks = [];

  for (const res of results) {
    if (res.status === "fulfilled" && Array.isArray(res.value)) {
      for (const item of res.value) {
        if (item.isEmbed) {
          embedFallbacks.push(item.url);
        } else if (item.url) {
          allStreams.push(item);
        }
      }
    }
  }

  return { directStreams: allStreams, backupEmbeds: embedFallbacks };
}
