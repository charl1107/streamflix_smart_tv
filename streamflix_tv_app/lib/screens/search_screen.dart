import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:streamflix_tv/providers/search_provider.dart';
import 'package:streamflix_tv/widgets/media_card.dart';
import 'package:streamflix_tv/widgets/loading_shimmer.dart';
import 'package:streamflix_tv/models/media_item.dart';

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
            padding: const EdgeInsets.symmetric(horizontal: 48.0, vertical: 16.0),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              autofocus: true,
              onChanged: _onSearchChanged,
              onSubmitted: _onSearchSubmitted,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              decoration: InputDecoration(
                hintText: 'Search for movies and TV shows...',
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white54),
                        onPressed: () {
                          _searchController.clear();
                          context.read<SearchProvider>().clearSearch();
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
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
                        padding: const EdgeInsets.symmetric(horizontal: 48.0, vertical: 16.0),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5,
                          childAspectRatio: 2 / 3,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
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
