import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    // Drop the on-screen keyboard so the results underneath become visible
    // and reachable with the D-pad. Without this the IME stays open on top of
    // the grid and the remote can never leave the text field.
    _moveFocusToResults();
  }

  /// Hands focus from the search field to the first result card and hides the
  /// soft keyboard. This is the "escape hatch" out of the text field on a TV
  /// remote: press Down (or the keyboard's Search/Done key) to enter the grid.
  void _moveFocusToResults() {
    final hasResults = context.read<SearchProvider>().searchResults.isNotEmpty;
    if (_searchFocusNode.hasFocus) {
      if (hasResults) {
        // nextFocus() moves to the first focusable result AND unfocuses the
        // field, which dismisses the keyboard in one step.
        _searchFocusNode.nextFocus();
      } else {
        _searchFocusNode.unfocus();
      }
    } else if (hasResults) {
      FocusScope.of(context).focusInDirection(TraversalDirection.down);
    }
  }

  void _navigateToDetail(MediaItem item) {
    Navigator.pushNamed(context, '/detail', arguments: item);
  }

  @override
  Widget build(BuildContext context) {
    final searchProvider = context.watch<SearchProvider>();

    return Scaffold(
      // A non-focusable wrapper that lets us catch the D-pad Down press while
      // the search field is focused. Key events bubble up from the focused
      // TextField to this ancestor when the field itself does not consume them.
      body: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: (node, event) {
          if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
            return KeyEventResult.ignored;
          }
          if (_searchFocusNode.hasFocus &&
              event.logicalKey == LogicalKeyboardKey.arrowDown) {
            _moveFocusToResults();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Column(
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
                textInputAction: TextInputAction.search,
                onChanged: _onSearchChanged,
                onSubmitted: _onSearchSubmitted,
                style: const TextStyle(color: Colors.white, fontSize: 17),
                decoration: InputDecoration(
                  hintText: 'Search for movies, shows, and anime...',
                  hintStyle:
                      const TextStyle(color: Colors.white54, fontSize: 16),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Color(0xFFE50914),
                    size: 24,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear_rounded,
                            color: Colors.white54,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            context.read<SearchProvider>().clearSearch();
                            _searchFocusNode.requestFocus();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFF141417),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(
                      color: Color(0x2EFFFFFF),
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(
                      color: Color(0x2EFFFFFF),
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(
                      color: Color(0xFFE50914),
                      width: 2,
                    ),
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
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 18,
                            ),
                          ),
                        )
                      : FocusTraversalGroup(
                          child: GridView.builder(
                            padding: EdgeInsets.symmetric(
                              horizontal: TvLayout.horizontalInset(context),
                              vertical: TvLayout.sectionGap(context),
                            ),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
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
            ),
          ],
        ),
      ),
    );
  }
}
