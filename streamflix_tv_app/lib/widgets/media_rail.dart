import 'package:flutter/material.dart';
import 'package:streamflix_tv/models/media_item.dart';
import 'package:streamflix_tv/widgets/media_card.dart';
import 'package:streamflix_tv/widgets/loading_shimmer.dart';
import 'package:streamflix_tv/config/tv_layout.dart';

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
          padding: EdgeInsets.symmetric(
            horizontal: TvLayout.horizontalInset(context),
            vertical: TvLayout.sectionGap(context) / 2,
          ),
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
          height: TvLayout.railHeight(context),
          child: isLoading
              ? Padding(
                  padding: EdgeInsets.symmetric(horizontal: TvLayout.horizontalInset(context)),
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
                      padding: EdgeInsets.symmetric(
                        horizontal: TvLayout.horizontalInset(context),
                        vertical: 8,
                      ),
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.none,
                      itemCount: items.length,
                      separatorBuilder: (context, index) => SizedBox(width: TvLayout.sectionGap(context)),
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
