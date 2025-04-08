import 'package:ai_pollinator_guardian/features/community_map/providers/community_map_provider.dart';
import 'package:ai_pollinator_guardian/features/community_map/screens/community_map_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/chat_assistant/providers/chat_provider.dart';
import 'features/chat_assistant/screens/chat_screen.dart';
// import 'features/authentication/screens/login_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/pollinator_id/screens/pollinator_id_screen.dart';
import 'features/garden_scanner/screens/garden_scanner_screen.dart';

import 'constants/app_colors.dart';

class PollinatorGuardianApp extends StatelessWidget {
  const PollinatorGuardianApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => CommunityMapProvider()),
      ],
      child: MaterialApp(
        title: 'AI Pollinator Guardian',
        theme: ThemeData(
          primarySwatch: AppColors.primarySwatch,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          fontFamily: 'Roboto',
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const HomeScreen(),
          '/chat': (context) => const ChatScreen(),
          '/garden': (context) => const GardenScannerScreen(),
          '/identify': (context) => const PollinatorIdScreen(),
          // '/login': (context) => const LoginScreen(),
          '/map': (context) => const CommunityMapScreen(),
        },
      ),
    );
  }
}