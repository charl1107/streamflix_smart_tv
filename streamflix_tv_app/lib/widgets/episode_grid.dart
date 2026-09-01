import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:streamflix_tv/config/api_config.dart';
import 'package:streamflix_tv/models/season_episode.dart';
import 'package:streamflix_tv/widgets/tv_focus_wrapper.dart';

class EpisodeGrid extends StatelessWidget {
  final List<dynamic> episodes;
  final Function(int) onEpisodeTap;

  const EpisodeGrid({
    super.key,
    required this.episodes,
    required this.onEpisodeTap,
  });

  @override
  Widget build(BuildContext context) {
    if (episodes.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text('No episodes available', style: TextStyle(color: Colors.white70)),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 16 / 12,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: episodes.length,
      itemBuilder: (context, index) {
        final ep = episodes[index];
        int episodeNumber = 0;
        String title = '';
        String? stillPath;

        if (ep is Episode) {
          episodeNumber = ep.episodeNumber;
          title = ep.name.isNotEmpty ? ep.name : 'Episode $episodeNumber';
          stillPath = ep.stillPath;
        } else if (ep is Map<String, dynamic>) {
          episodeNumber = ep['number'] ?? ep['episode_number'] ?? ep['episodeNumber'] ?? (index + 1);
          title = ep['title'] ?? ep['name'] ?? 'Episode $episodeNumber';
          stillPath = ep['still_path'] ?? ep['image'] ?? ep['stillPath'];
        }

        return TvFocusWrapper(
          onTap: () => onEpisodeTap(episodeNumber),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2C),
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: stillPath != null && stillPath.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: ApiConfig.posterUrl(stillPath),
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[800],
                            child: const Icon(Icons.tv, color: Colors.white54),
                          ),
                        )
                      : Container(
                          color: Colors.grey[800],
                          child: const Icon(Icons.tv, color: Colors.white54),
                        ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Episode $episodeNumber',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
