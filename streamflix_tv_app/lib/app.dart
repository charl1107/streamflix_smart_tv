import 'package:flutter/material.dart';
import 'package:streamflix_tv/config/theme.dart';
import 'package:streamflix_tv/navigation/app_navigation.dart';
import 'package:streamflix_tv/screens/detail_screen.dart';
import 'package:streamflix_tv/screens/player_screen.dart';
import 'package:streamflix_tv/screens/player_webview_screen.dart';

class StreamflixApp extends StatelessWidget {
  const StreamflixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Streamflix',
      debugShowCheckedModeBanner: false,
      theme: TvTheme.darkTheme,
      home: const AppNavigation(),
      routes: {
        '/detail': (context) => const DetailScreen(),
        '/player': (context) => const PlayerScreen(),
        '/player_webview': (context) => const PlayerWebViewScreen(),
      },
    );
  }
}
