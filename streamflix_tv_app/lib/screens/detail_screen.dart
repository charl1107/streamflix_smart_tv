import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:streamflix_tv/models/media_item.dart';
import 'package:streamflix_tv/config/api_config.dart';
import 'package:streamflix_tv/services/tmdb_service.dart';
import 'package:streamflix_tv/services/embed_service.dart';
import 'package:streamflix_tv/widgets/tv_focus_wrapper.dart';
import 'package:streamflix_tv/widgets/episode_grid.dart';
import 'package:streamflix_tv/widgets/media_rail.dart';

class DetailScreen extends StatefulWidget {
  const DetailScreen({super.key});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late MediaItem _mediaItem;
  bool _isLoading = true;
  MediaItem? _fullDetails;
  
  List<dynamic> _episodes = [];
  int _selectedSeason = 1;
  int _totalSeasons = 1;
  List<MediaItem> _recommendations = [];
  List<Map<String, dynamic>> _cast = [];

  final TmdbService _tmdbService = TmdbService();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is MediaItem) {
      _mediaItem = args;
      _loadDetails();
    }
  }

  Future<void> _loadDetails() async {
    setState(() => _isLoading = true);
    
    try {
      if (_mediaItem.mediaType == 'tv') {
        final tvId = int.tryParse(_mediaItem.id.toString()) ?? 0;
        _fullDetails = await _tmdbService.getTvDetails(tvId);
        _totalSeasons = _fullDetails?.numberOfSeasons ?? _fullDetails?.seasons.length ?? 1;
        if (_totalSeasons < 1) _totalSeasons = 1;
        _cast = _fullDetails?.cast ?? [];
        _recommendations = _fullDetails?.recommendations ?? [];
        await _loadTvSeason(_selectedSeason);
      } else {
        final movieId = int.tryParse(_mediaItem.id.toString()) ?? 0;
        _fullDetails = await _tmdbService.getMovieDetails(movieId);
        _cast = _fullDetails?.cast ?? [];
        _recommendations = _fullDetails?.recommendations ?? [];
      }
    } catch (e) {
      debugPrint('Error loading details: $e');
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadTvSeason(int seasonNum) async {
    try {
      final tvId = int.tryParse(_mediaItem.id.toString()) ?? 0;
      final seasonEpisodes = await _tmdbService.getTvSeason(tvId, seasonNum);
      if (mounted) {
        setState(() {
          _episodes = seasonEpisodes;
        });
      }
    } catch (e) {
      debugPrint('Error loading season: $e');
    }
  }

  void _onPlayPressed() {
    final isAnime = _mediaItem.mediaType == 'anime';
    final embedUrl = isAnime 
        ? EmbedService.getAnimeUrl(_mediaItem.id, 1, 1)
        : EmbedService.getMovieUrl(_mediaItem.id);
    Navigator.pushNamed(
      context, 
      '/player', 
      arguments: {
        'embedUrl': embedUrl, 
        'title': _mediaItem.title,
        'mediaId': _mediaItem.id,
        'mediaType': _mediaItem.mediaType,
      },
    );
  }

  void _onEpisodeTap(int episodeNumber) {
    final isAnime = _mediaItem.mediaType == 'anime';
    final embedUrl = isAnime
        ? EmbedService.getAnimeUrl(_mediaItem.id, _selectedSeason, episodeNumber)
        : EmbedService.getTvUrl(_mediaItem.id, _selectedSeason, episodeNumber);

    Navigator.pushNamed(
      context, 
      '/player', 
      arguments: {
        'embedUrl': embedUrl,
        'title': '${_mediaItem.title} - S$_selectedSeason Ep $episodeNumber',
        'mediaId': _mediaItem.id,
        'mediaType': _mediaItem.mediaType,
        'season': _selectedSeason,
        'episode': episodeNumber,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = _fullDetails ?? _mediaItem;
    final title = item.title.isNotEmpty ? item.title : 'Unknown';
    final year = item.year?.toString() ?? '';
    
    return Scaffold(
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.blue))
        : SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Backdrop & Title
                SizedBox(
                  height: 400,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: ApiConfig.backdropUrl(item.backdropPath ?? item.posterPath ?? ''),
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => Container(color: Colors.grey[900]),
                      ),
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.transparent, Colors.black87, Colors.black],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 48,
                        bottom: 48,
                        right: 48,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (item.posterPath != null && item.posterPath!.isNotEmpty)
                              Container(
                                width: 140,
                                height: 210,
                                margin: const EdgeInsets.only(right: 24),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  image: DecorationImage(
                                    image: CachedNetworkImageProvider(
                                      ApiConfig.posterUrl(item.posterPath!),
                                    ),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      if (item.rating > 0) ...[
                                        const Icon(Icons.star, color: Colors.yellow, size: 20),
                                        const SizedBox(width: 4),
                                        Text(
                                          item.rating.toStringAsFixed(1),
                                          style: const TextStyle(fontSize: 16, color: Colors.white),
                                        ),
                                        const SizedBox(width: 16),
                                      ],
                                      if (year.isNotEmpty) ...[
                                        Text(year, style: const TextStyle(fontSize: 16, color: Colors.white70)),
                                        const SizedBox(width: 16),
                                      ],
                                      if (item.runtime != null)
                                        Text('${item.runtime} min', style: const TextStyle(fontSize: 16, color: Colors.white70)),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    item.overview ?? '',
                                    maxLines: 4,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                                  ),
                                  const SizedBox(height: 24),
                                  if (item.mediaType == 'movie')
                                    TvFocusWrapper(
                                      onTap: _onPlayPressed,
                                      autofocus: true,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: Colors.blue,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.play_arrow, color: Colors.white),
                                            SizedBox(width: 8),
                                            Text(
                                              'Play Movie',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: 24,
                        left: 24,
                        child: TvFocusWrapper(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Icon(Icons.arrow_back, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // TV Shows Episodes Section
                if (item.mediaType == 'tv') ...[
                  if (_totalSeasons > 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 48.0, vertical: 16.0),
                      child: DropdownButton<int>(
                        value: _selectedSeason,
                        dropdownColor: const Color(0xFF1E1E1E),
                        style: const TextStyle(color: Colors.white, fontSize: 18),
                        items: List.generate(
                          _totalSeasons, 
                          (index) => DropdownMenuItem(
                            value: index + 1,
                            child: Text('Season ${index + 1}'),
                          ),
                        ),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedSeason = val;
                            });
                            _loadTvSeason(val);
                          }
                        },
                      ),
                    ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 48.0, vertical: 8.0),
                    child: Text(
                      'Episodes',
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: EpisodeGrid(
                      episodes: _episodes,
                      onEpisodeTap: _onEpisodeTap,
                    ),
                  ),
                ],

                // Cast Section
                if (_cast.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 48.0, vertical: 16.0),
                    child: Text('Cast', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  ),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 48.0),
                      itemCount: _cast.length,
                      itemBuilder: (context, index) {
                        final actor = _cast[index];
                        final profilePath = actor['profile_path'];
                        return Container(
                          width: 80,
                          margin: const EdgeInsets.only(right: 16),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 32,
                                backgroundImage: profilePath != null 
                                  ? CachedNetworkImageProvider(ApiConfig.posterUrl(profilePath)) 
                                  : null,
                                backgroundColor: Colors.grey[800],
                                child: profilePath == null ? const Icon(Icons.person, color: Colors.white54) : null,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                actor['name'] ?? '',
                                maxLines: 2,
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],

                // Recommendations
                if (_recommendations.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  MediaRail(
                    title: 'More Like This',
                    items: _recommendations,
                    onItemTap: (recItem) {
                      Navigator.pushReplacementNamed(context, '/detail', arguments: recItem);
                    },
                  ),
                ],
                
                const SizedBox(height: 48),
              ],
            ),
          ),
    );
  }
}
