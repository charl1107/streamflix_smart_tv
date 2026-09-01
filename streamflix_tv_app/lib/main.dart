import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:streamflix_tv/app.dart';
import 'package:streamflix_tv/providers/media_provider.dart';
import 'package:streamflix_tv/providers/search_provider.dart';
import 'package:streamflix_tv/providers/player_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Force landscape for TV
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  // Hide status bar and nav bar for immersive TV experience
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MediaProvider()),
        ChangeNotifierProvider(create: (_) => SearchProvider()),
        ChangeNotifierProvider(create: (_) => PlayerProvider()),
      ],
      child: const StreamflixApp(),
    ),
  );
}
