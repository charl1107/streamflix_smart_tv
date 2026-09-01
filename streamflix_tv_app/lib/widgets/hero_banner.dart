import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:streamflix_tv/models/media_item.dart';
import 'package:streamflix_tv/config/api_config.dart';
import 'package:streamflix_tv/widgets/tv_focus_wrapper.dart';

class HeroBanner extends StatefulWidget {
  final List<MediaItem> items;
  final Function(MediaItem) onItemTap;

  const HeroBanner({
    super.key,
    required this.items,
    required this.onItemTap,
  });

  @override
  State<HeroBanner> createState() => _HeroBannerState();
}

class _HeroBannerState extends State<HeroBanner> {
  late PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _startAutoPlay();
  }

  void _startAutoPlay() {
    if (widget.items.isEmpty) return;
    _timer = Timer.periodic(const Duration(seconds: 6), (timer) {
      if (_pageController.hasClients) {
        int nextPage = _currentPage + 1;
        if (nextPage >= widget.items.length) {
          nextPage = 0;
        }
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return const SizedBox(height: 300);
    }

    return SizedBox(
      width: double.infinity,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemCount: widget.items.length,
              itemBuilder: (context, index) {
                final item = widget.items[index];
                final title = item.title.isNotEmpty ? item.title : 'Unknown';
                
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // Backdrop Image
                    CachedNetworkImage(
                      imageUrl: ApiConfig.backdropUrl(item.backdropPath ?? item.posterPath ?? ''),
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Container(color: Colors.grey[900]),
                    ),
                    // Gradient Overlay
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.transparent, Colors.black87, Colors.black],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: [0.3, 0.8, 1.0],
                        ),
                      ),
                    ),
                    // Content
                    Positioned(
                      left: 48,
                      bottom: 48,
                      right: 48,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          if (item.rating > 0)
                            Row(
                              children: [
                                const Icon(Icons.star, color: Colors.yellow, size: 20),
                                const SizedBox(width: 4),
                                Text(
                                  item.rating.toStringAsFixed(1),
                                  style: const TextStyle(color: Colors.white, fontSize: 16),
                                ),
                              ],
                            ),
                          const SizedBox(height: 8),
                          Text(
                            item.overview ?? '',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 16),
                          TvFocusWrapper(
                            onTap: () => widget.onItemTap(item),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Watch Now',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            // Page Indicators
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.items.length,
                  (index) => Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentPage == index ? Colors.white : Colors.white38,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
