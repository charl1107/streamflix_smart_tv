import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:streamflix_tv/providers/media_provider.dart';
import 'package:streamflix_tv/widgets/hero_banner.dart';
import 'package:streamflix_tv/widgets/media_rail.dart';
import 'package:streamflix_tv/models/media_item.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        context.read<MediaProvider>().loadHome();
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
            HeroBanner(
              items: provider.trendingMovies.take(5).toList(),
              onItemTap: _navigateToDetail,
            ),
            const SizedBox(height: 24),
            MediaRail(
              title: 'Trending Movies',
              items: provider.trendingMovies,
              isLoading: provider.isHomeLoading,
              onItemTap: _navigateToDetail,
            ),
            const SizedBox(height: 16),
            MediaRail(
              title: 'Popular TV Shows',
              items: provider.popularShows,
              isLoading: provider.isHomeLoading,
              onItemTap: _navigateToDetail,
            ),
            const SizedBox(height: 16),
            MediaRail(
              title: 'Top Rated Movies',
              items: provider.topRatedMovies,
              isLoading: provider.isHomeLoading,
              onItemTap: _navigateToDetail,
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}
