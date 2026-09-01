import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:streamflix_tv/providers/media_provider.dart';
import 'package:streamflix_tv/widgets/hero_banner.dart';
import 'package:streamflix_tv/widgets/media_rail.dart';
import 'package:streamflix_tv/widgets/genre_chips.dart';
import 'package:streamflix_tv/models/media_item.dart';
import 'package:streamflix_tv/models/genre.dart';

class ShowsScreen extends StatefulWidget {
  const ShowsScreen({super.key});

  @override
  State<ShowsScreen> createState() => _ShowsScreenState();
}

class _ShowsScreenState extends State<ShowsScreen> {
  Genre? _selectedGenre;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        context.read<MediaProvider>().loadShows();
      }
    });
  }

  void _navigateToDetail(MediaItem item) {
    Navigator.pushNamed(context, '/detail', arguments: item);
  }

  void _onGenreSelected(Genre? genre) {
    setState(() {
      _selectedGenre = genre;
    });
    if (genre != null) {
      context.read<MediaProvider>().loadShowsByGenre(genre.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MediaProvider>();
    final showGenreFiltered = _selectedGenre != null;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HeroBanner(
              items: provider.trendingShows.take(5).toList(),
              onItemTap: _navigateToDetail,
            ),
            const SizedBox(height: 16),
            GenreChips(
              genres: provider.showGenres,
              selectedGenre: _selectedGenre,
              onSelected: _onGenreSelected,
            ),
            const SizedBox(height: 16),
            if (showGenreFiltered)
              MediaRail(
                title: '${_selectedGenre!.name} Shows',
                items: provider.genreFilteredShows,
                isLoading: provider.isFiltering,
                onItemTap: _navigateToDetail,
              )
            else ...[
              MediaRail(
                title: 'Trending Shows',
                items: provider.trendingShows,
                isLoading: provider.isLoading,
                onItemTap: _navigateToDetail,
              ),
              const SizedBox(height: 16),
              MediaRail(
                title: 'Popular Shows',
                items: provider.popularShows,
                isLoading: provider.isLoading,
                onItemTap: _navigateToDetail,
              ),
              const SizedBox(height: 16),
              MediaRail(
                title: 'Top Rated Shows',
                items: provider.topRatedShows,
                isLoading: provider.isLoading,
                onItemTap: _navigateToDetail,
              ),
            ],
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}
