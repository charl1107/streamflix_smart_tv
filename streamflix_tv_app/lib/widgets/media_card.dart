import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:streamflix_tv/models/media_item.dart';
import 'package:streamflix_tv/config/api_config.dart';
import 'package:streamflix_tv/widgets/tv_focus_wrapper.dart';
import 'package:streamflix_tv/widgets/loading_shimmer.dart';

class MediaCard extends StatelessWidget {
  final MediaItem item;
  final VoidCallback onTap;

  const MediaCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final year = item.year?.toString();
    final title = item.title.isNotEmpty ? item.title : 'Unknown';

    return TvFocusWrapper(
      onTap: onTap,
      child: SizedBox(
        width: 160,
        height: 240,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Poster Image
              CachedNetworkImage(
                imageUrl: ApiConfig.posterUrl(item.posterPath ?? ''),
                fit: BoxFit.cover,
                placeholder: (context, url) => const ShimmerCard(),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[800],
                  child: const Icon(Icons.movie, size: 40, color: Colors.white54),
                ),
              ),
              // Gradient Overlay at bottom for title readability
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 80,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Colors.black87, Colors.black],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              // Title text at bottom
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
              // Rating Badge
              if (item.rating > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Colors.yellow, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          item.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              // Year Badge
              if (year != null)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      year,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
