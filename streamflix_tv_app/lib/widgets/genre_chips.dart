import 'package:flutter/material.dart';
import 'package:streamflix_tv/models/genre.dart';
import 'package:streamflix_tv/widgets/tv_focus_wrapper.dart';
import 'package:streamflix_tv/config/tv_layout.dart';

class GenreChips extends StatelessWidget {
  final List<Genre> genres;
  final Genre? selectedGenre;
  final Function(Genre?) onSelected;

  const GenreChips({
    super.key,
    required this.genres,
    required this.selectedGenre,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (genres.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 60,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(
          horizontal: TvLayout.horizontalInset(context),
          vertical: 8.0,
        ),
        scrollDirection: Axis.horizontal,
        itemCount: genres.length + 1, // +1 for "All"
        itemBuilder: (context, index) {
          final isAll = index == 0;
          final genre = isAll ? null : genres[index - 1];
          final isSelected = selectedGenre?.id == genre?.id;

          return Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: TvFocusWrapper(
              onTap: () => onSelected(genre),
              borderRadius: BorderRadius.circular(24),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFE50914) : const Color(0xFF141417),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected ? const Color(0xFFE50914) : const Color(0x2EFFFFFF),
                    width: 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFFE50914).withValues(alpha: 0.4),
                            blurRadius: 10,
                          ),
                        ]
                      : [],
                ),
                child: Center(
                  child: Text(
                    isAll ? 'All' : genre!.name,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
