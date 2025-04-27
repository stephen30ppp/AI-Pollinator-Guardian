import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'constants/design_tokens.dart';
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
          useMaterial3: true,
          colorScheme: DesignTokens.lightColorScheme,
          fontFamily: 'Roboto',
          scaffoldBackgroundColor: DesignTokens.lightColorScheme.background,
          appBarTheme: AppBarTheme(
            backgroundColor: DesignTokens.lightColorScheme.primary,
            foregroundColor: DesignTokens.lightColorScheme.onPrimary,
            elevation: 0,
            centerTitle: true,
            titleTextStyle: TextStyle(
              color: DesignTokens.lightColorScheme.onPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
            iconTheme: IconThemeData(color: DesignTokens.lightColorScheme.onPrimary),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: DesignTokens.lightColorScheme.surfaceVariant.withOpacity(0.3),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.l,
              vertical: DesignTokens.m,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
              borderSide: BorderSide(
                color: DesignTokens.lightColorScheme.outline,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
              borderSide: BorderSide(
                color: DesignTokens.lightColorScheme.outline.withOpacity(0.5),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
              borderSide: BorderSide(
                color: DesignTokens.lightColorScheme.primary,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
              borderSide: BorderSide(
                color: DesignTokens.lightColorScheme.error,
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
              borderSide: BorderSide(
                color: DesignTokens.lightColorScheme.error,
                width: 1.5,
              ),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignTokens.lightColorScheme.primary,
              foregroundColor: DesignTokens.lightColorScheme.onPrimary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: DesignTokens.m),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
              ),
            ),
          ),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: DesignTokens.darkColorScheme,
          fontFamily: 'Roboto',
          scaffoldBackgroundColor: DesignTokens.darkColorScheme.background,
          appBarTheme: AppBarTheme(
            backgroundColor: DesignTokens.darkColorScheme.primaryContainer,
            foregroundColor: DesignTokens.darkColorScheme.onPrimaryContainer,
            elevation: 0,
            centerTitle: true,
            titleTextStyle: TextStyle(
              color: DesignTokens.darkColorScheme.onPrimaryContainer,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
            iconTheme: IconThemeData(color: DesignTokens.darkColorScheme.onPrimaryContainer),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: DesignTokens.darkColorScheme.surfaceVariant.withOpacity(0.3),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.l,
              vertical: DesignTokens.m,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
              borderSide: BorderSide(
                color: DesignTokens.darkColorScheme.outline,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
              borderSide: BorderSide(
                color: DesignTokens.darkColorScheme.outline.withOpacity(0.5),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
              borderSide: BorderSide(
                color: DesignTokens.darkColorScheme.primary,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
              borderSide: BorderSide(
                color: DesignTokens.darkColorScheme.error,
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
              borderSide: BorderSide(
                color: DesignTokens.darkColorScheme.error,
                width: 1.5,
              ),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignTokens.darkColorScheme.primary, 
              foregroundColor: DesignTokens.darkColorScheme.onPrimary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: DesignTokens.m),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
              ),
            ),
          ),
        ),
        themeMode: ThemeMode.system, // Respect system settings
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