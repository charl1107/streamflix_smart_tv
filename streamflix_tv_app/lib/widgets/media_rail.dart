import 'package:flutter/material.dart';
import 'package:streamflix_tv/models/media_item.dart';
import 'package:streamflix_tv/widgets/media_card.dart';
import 'package:streamflix_tv/widgets/loading_shimmer.dart';

class MediaRail extends StatelessWidget {
  final dynamic title; // String or Widget
  final List<MediaItem> items;
  final Function(MediaItem) onItemTap;
  final bool isLoading;

  const MediaRail({
    super.key,
    required this.title,
    required this.items,
    required this.onItemTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: title is String
              ? Text(
                  title as String,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : title as Widget,
        ),
        SizedBox(
          height: 180, // adjusted height for rail aspect ratio
          child: isLoading
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0),
                  child: ShimmerRail(),
                )
              : items.isEmpty
                  ? const Center(
                      child: Text(
                        'No items found',
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      scrollDirection: Axis.horizontal,
                      itemCount: items.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        return MediaCard(
                          item: items[index],
                          onTap: () => onItemTap(items[index]),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
