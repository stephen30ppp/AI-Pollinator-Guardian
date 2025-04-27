import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import './providers/auth_provider.dart';
import './screens/login_screen.dart';
import '../../../features/home/screens/home_screen.dart';
import '../../../constants/design_tokens.dart';
import 'package:lottie/lottie.dart';

/// A wrapper widget that decides whether to show auth screens or the main app
/// based on authentication state with smooth transitions.
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isInit = false;

  @override
  void initState() {
    super.initState();
    
    // Animation controller for transitions
    _animationController = AnimationController(
      vsync: this,
      duration: DesignTokens.animationNormal,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
    
    // Initialize auth state when the wrapper is created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthProvider>(context, listen: false).initializeAuth();
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;

    // Start the animation once the auth status is determined
    if (!_isInit && authProvider.status != AuthStatus.initial) {
      _isInit = true;
      _animationController.forward();
    }

    // Show loading indicator during initial auth check
    if (authProvider.status == AuthStatus.initial) {
      return Scaffold(
        backgroundColor: colorScheme.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo with Lottie animation
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  // Note: Need to add this Lottie asset
                  child: Lottie.asset(
                    'assets/animations/bee_loading.json',
                    width: 80,
                    height: 80,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Text(
                      '🐝',
                      style: TextStyle(fontSize: 50),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: DesignTokens.l),
              Text(
                'Loading...',
                style: DesignTokens.bodyLarge.copyWith(
                  color: colorScheme.onBackground,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Use FadeTransition for smooth transitions between states
    return FadeTransition(
      opacity: _fadeAnimation,
      child: authProvider.isAuthenticated
          ? const HomeScreen()
          : const LoginScreen(),
    );
  }
}