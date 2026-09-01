import 'package:flutter/material.dart';
import 'package:streamflix_tv/models/genre.dart';
import 'package:streamflix_tv/widgets/tv_focus_wrapper.dart';

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
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
        scrollDirection: Axis.horizontal,
        itemCount: genres.length + 1, // +1 for "All"
        itemBuilder: (context, index) {
          final isAll = index == 0;
          final genre = isAll ? null : genres[index - 1];
          final isSelected = selectedGenre?.id == genre?.id;

          return Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: TvFocusWrapper(
              onTap: () => onSelected(genre),
              child: ChoiceChip(
                label: Text(
                  isAll ? 'All' : genre!.name,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                selected: isSelected,
                selectedColor: Colors.blue,
                backgroundColor: const Color(0xFF1E1E1E), // Dark surface
                onSelected: (_) => onSelected(genre),
                // Disable default ChoiceChip focus to let TvFocusWrapper handle it
                focusNode: FocusNode(canRequestFocus: false),
              ),
            ),
          );
        },
      ),
    );
  }
}
