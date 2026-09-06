import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:streamflix_tv/providers/search_provider.dart';
import 'package:streamflix_tv/widgets/media_card.dart';
import 'package:streamflix_tv/widgets/loading_shimmer.dart';
import 'package:streamflix_tv/models/media_item.dart';
import 'package:streamflix_tv/config/tv_layout.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (query.trim().isNotEmpty) {
      context.read<SearchProvider>().search(query);
    } else {
      context.read<SearchProvider>().clearSearch();
    }
  }

  void _onSearchSubmitted(String query) {
    if (query.trim().isNotEmpty) {
      context.read<SearchProvider>().searchImmediate(query);
    }
  }

  void _navigateToDetail(MediaItem item) {
    Navigator.pushNamed(context, '/detail', arguments: item);
  }

  @override
  Widget build(BuildContext context) {
    final searchProvider = context.watch<SearchProvider>();

    return Scaffold(
      body: Column(
        children: [
          // Spacing for top floating nav bar
          const SizedBox(height: 80),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: TvLayout.horizontalInset(context),
              vertical: TvLayout.sectionGap(context),
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              autofocus: false,
              onChanged: _onSearchChanged,
              onSubmitted: _onSearchSubmitted,
              style: const TextStyle(color: Colors.white, fontSize: 17),
              decoration: InputDecoration(
                hintText: 'Search for movies, shows, and anime...',
                hintStyle: const TextStyle(color: Colors.white54, fontSize: 16),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFE50914), size: 24),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, color: Colors.white54),
                        onPressed: () {
                          _searchController.clear();
                          context.read<SearchProvider>().clearSearch();
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFF141417),
                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: Color(0x2EFFFFFF), width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: Color(0x2EFFFFFF), width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: Color(0xFFE50914), width: 2),
                ),
              ),
            ),
          ),
          Expanded(
            child: searchProvider.isLoading
                ? const ShimmerGrid()
                : searchProvider.searchResults.isEmpty
                    ? Center(
                        child: Text(
                          _searchController.text.isEmpty
                              ? 'Type a title to search'
                              : 'No movies or TV shows found for "${_searchController.text}"',
                          style: const TextStyle(color: Colors.white54, fontSize: 18),
                        ),
                      )
                    : GridView.builder(
                        padding: EdgeInsets.symmetric(
                          horizontal: TvLayout.horizontalInset(context),
                          vertical: TvLayout.sectionGap(context),
                        ),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: TvLayout.gridColumns(context),
                          childAspectRatio: 2 / 3,
                          crossAxisSpacing: TvLayout.sectionGap(context),
                          mainAxisSpacing: TvLayout.sectionGap(context),
                        ),
                        itemCount: searchProvider.searchResults.length,
                        itemBuilder: (context, index) {
                          final item = searchProvider.searchResults[index];
                          return MediaCard(
                            item: item,
                            onTap: () => _navigateToDetail(item),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
