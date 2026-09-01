import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:streamflix_tv/providers/media_provider.dart';
import 'package:streamflix_tv/widgets/hero_banner.dart';
import 'package:streamflix_tv/widgets/media_rail.dart';
import 'package:streamflix_tv/widgets/genre_chips.dart';
import 'package:streamflix_tv/models/media_item.dart';
import 'package:streamflix_tv/models/genre.dart';

class MoviesScreen extends StatefulWidget {
  const MoviesScreen({super.key});

  @override
  State<MoviesScreen> createState() => _MoviesScreenState();
}

class _MoviesScreenState extends State<MoviesScreen> {
  Genre? _selectedGenre;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        context.read<MediaProvider>().loadMovies();
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
      context.read<MediaProvider>().loadMoviesByGenre(genre.id);
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
              items: provider.trendingMovies.take(5).toList(),
              onItemTap: _navigateToDetail,
            ),
            const SizedBox(height: 16),
            GenreChips(
              genres: provider.movieGenres,
              selectedGenre: _selectedGenre,
              onSelected: _onGenreSelected,
            ),
            const SizedBox(height: 16),
            if (showGenreFiltered)
              MediaRail(
                title: '${_selectedGenre!.name} Movies',
                items: provider.genreFilteredMovies,
                isLoading: provider.isFiltering,
                onItemTap: _navigateToDetail,
              )
            else ...[
              MediaRail(
                title: 'Trending Movies',
                items: provider.trendingMovies,
                isLoading: provider.isLoading,
                onItemTap: _navigateToDetail,
              ),
              const SizedBox(height: 16),
              MediaRail(
                title: 'Popular Movies',
                items: provider.popularMovies,
                isLoading: provider.isLoading,
                onItemTap: _navigateToDetail,
              ),
              const SizedBox(height: 16),
              MediaRail(
                title: 'Top Rated Movies',
                items: provider.topRatedMovies,
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
