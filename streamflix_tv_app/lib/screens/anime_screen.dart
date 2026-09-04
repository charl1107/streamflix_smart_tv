import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:streamflix_tv/providers/media_provider.dart';
import 'package:streamflix_tv/widgets/hero_banner.dart';
import 'package:streamflix_tv/widgets/media_rail.dart';
import 'package:streamflix_tv/models/media_item.dart';

class AnimeScreen extends StatefulWidget {
  const AnimeScreen({super.key});

  @override
  State<AnimeScreen> createState() => _AnimeScreenState();
}

class _AnimeScreenState extends State<AnimeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        context.read<MediaProvider>().loadAnime();
      }
    });
  }

  void _navigateToDetail(MediaItem item) {
    Navigator.pushNamed(context, '/detail', arguments: item);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MediaProvider>();

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (provider.trendingAnime.isNotEmpty)
              HeroBanner(
                items: provider.trendingAnime.take(5).toList(),
                onItemTap: _navigateToDetail,
              ),
            const SizedBox(height: 24),
            MediaRail(
              title: 'Trending Anime',
              items: provider.trendingAnime,
              isLoading: provider.isAnimeLoading,
              onItemTap: _navigateToDetail,
            ),
            const SizedBox(height: 16),
            MediaRail(
              title: 'Popular Anime',
              items: provider.popularAnime,
              isLoading: provider.isAnimeLoading,
              onItemTap: _navigateToDetail,
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}
