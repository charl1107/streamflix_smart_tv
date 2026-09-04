import 'package:flutter/material.dart';
import 'package:streamflix_tv/screens/home_screen.dart';
import 'package:streamflix_tv/screens/movies_screen.dart';
import 'package:streamflix_tv/screens/shows_screen.dart';
import 'package:streamflix_tv/screens/anime_screen.dart';
import 'package:streamflix_tv/screens/search_screen.dart';
import 'package:streamflix_tv/widgets/tv_focus_wrapper.dart';

class AppNavigation extends StatefulWidget {
  const AppNavigation({super.key});

  @override
  State<AppNavigation> createState() => _AppNavigationState();
}

class _AppNavigationState extends State<AppNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    MoviesScreen(),
    ShowsScreen(),
    AnimeScreen(),
    SearchScreen(),
  ];

  final List<_NavDestination> _destinations = const [
    _NavDestination(title: 'Home', icon: Icons.home_rounded),
    _NavDestination(title: 'Movies', icon: Icons.movie_rounded),
    _NavDestination(title: 'Shows', icon: Icons.tv_rounded),
    _NavDestination(title: 'Anime', icon: Icons.auto_awesome_rounded),
    _NavDestination(title: 'Search', icon: Icons.search_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      body: Stack(
        children: [
          // Content screen occupying 100% width and height
          Positioned.fill(
            child: IndexedStack(
              index: _selectedIndex,
              children: _screens,
            ),
          ),

          // Floating Frosted Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.95),
                    Colors.black.withValues(alpha: 0.6),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.65, 1.0],
                ),
              ),
              child: Row(
                children: [
                  // Cineko Brand Header
                  Row(
                    children: [
                      // Cineko Red Playback Ring Logo
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFF141417),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFE50914), width: 2.2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFE50914).withValues(alpha: 0.45),
                              blurRadius: 14,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.play_arrow_rounded,
                            color: Color(0xFFE50914),
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'CINEKO',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                          Text(
                            'YOUR OPEN CINEMA',
                            style: TextStyle(
                              color: Color(0xFFFBBF24),
                              fontSize: 8.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(width: 48),

                  // Navigation Tabs (Pill style matching streamflix-cf)
                  Expanded(
                    child: Row(
                      children: List.generate(_destinations.length, (index) {
                        final dest = _destinations[index];
                        final isSelected = _selectedIndex == index;

                        return Padding(
                          padding: const EdgeInsets.only(right: 14.0),
                          child: TvFocusWrapper(
                            onTap: () {
                              setState(() {
                                _selectedIndex = index;
                              });
                            },
                            borderRadius: BorderRadius.circular(30),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFFE50914)
                                    : Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFFE50914)
                                      : const Color(0x2EFFFFFF),
                                  width: 1.2,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFFE50914).withValues(alpha: 0.45),
                                          blurRadius: 14,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    dest.icon,
                                    size: 17,
                                    color: isSelected ? Colors.white : Colors.white70,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    dest.title,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : Colors.white70,
                                      fontSize: 14.5,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavDestination {
  final String title;
  final IconData icon;

  const _NavDestination({required this.title, required this.icon});
}

