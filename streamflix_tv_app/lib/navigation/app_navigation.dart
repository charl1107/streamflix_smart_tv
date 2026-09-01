import 'package:flutter/material.dart';
import 'package:streamflix_tv/screens/home_screen.dart';
import 'package:streamflix_tv/screens/movies_screen.dart';
import 'package:streamflix_tv/screens/shows_screen.dart';
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
    SearchScreen(),
  ];

  final List<_NavDestination> _destinations = const [
    _NavDestination(title: 'Home', icon: Icons.home_rounded),
    _NavDestination(title: 'Movies', icon: Icons.movie_rounded),
    _NavDestination(title: 'TV Shows', icon: Icons.tv_rounded),
    _NavDestination(title: 'Search', icon: Icons.search_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Stack(
        children: [
          // Content screen occupying 100% width and height
          Positioned.fill(
            child: IndexedStack(
              index: _selectedIndex,
              children: _screens,
            ),
          ),

          // Floating Top Navigation Bar
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
                    Colors.black.withValues(alpha: 0.9),
                    Colors.black.withValues(alpha: 0.5),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
              child: Row(
                children: [
                  // App Brand Logo
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blueAccent.withValues(alpha: 0.4),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'STREAMFLIX',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(width: 48),

                  // Navigation Tabs
                  Expanded(
                    child: Row(
                      children: List.generate(_destinations.length, (index) {
                        final dest = _destinations[index];
                        final isSelected = _selectedIndex == index;

                        return Padding(
                          padding: const EdgeInsets.only(right: 16.0),
                          child: TvFocusWrapper(
                            onTap: () {
                              setState(() {
                                _selectedIndex = index;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.blueAccent.withValues(alpha: 0.25)
                                    : Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.blueAccent
                                      : Colors.white.withValues(alpha: 0.12),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    dest.icon,
                                    size: 18,
                                    color: isSelected ? Colors.blueAccent : Colors.white70,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    dest.title,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : Colors.white70,
                                      fontSize: 15,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      letterSpacing: 0.5,
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

