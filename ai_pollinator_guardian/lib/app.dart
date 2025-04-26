import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/community_map/providers/community_map_provider.dart';
import 'features/community_map/screens/community_map_screen.dart';
import 'features/chat_assistant/providers/chat_provider.dart';
import 'features/chat_assistant/screens/chat_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/pollinator_id/screens/pollinator_id_screen.dart';
import 'features/garden_scanner/screens/garden_scanner_screen.dart';
import 'features/authentication/providers/auth_provider.dart';
import 'features/authentication/screens/login_screen.dart';
import 'features/authentication/screens/signup_screen.dart';
import 'features/authentication/screens/forgot_password_screen.dart';
import 'features/authentication/screens/profile_screen.dart';
import 'features/authentication/auth_wrapper.dart';

import 'constants/app_colors.dart';

class PollinatorGuardianApp extends StatelessWidget {
  const PollinatorGuardianApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => CommunityMapProvider()),
      ],
      child: MaterialApp(
        title: 'AI Pollinator Guardian',
        theme: ThemeData(
          primarySwatch: AppColors.primarySwatch,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          fontFamily: 'Roboto',
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: const AppBarTheme(
            color: AppColors.primaryColor,
            elevation: 0,
            titleTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
            iconTheme: IconThemeData(color: Colors.white),
          ),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const AuthWrapper(),
          '/home': (context) => const HomeScreen(),
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignupScreen(),
          '/forgot-password': (context) => const ForgotPasswordScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/chat': (context) => const ChatScreen(),
          '/garden': (context) => const GardenScannerScreen(),
          '/identify': (context) => const PollinatorIdScreen(),
          '/map': (context) => const CommunityMapScreen(),
        },
      ),
    );
  }
}