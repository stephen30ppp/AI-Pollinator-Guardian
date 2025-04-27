import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../constants/design_tokens.dart';

enum AuthButtonType {
  primary,
  secondary,
  outline,
}

class AuthButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final AuthButtonType type;
  final IconData? icon;

  const AuthButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.type = AuthButtonType.primary,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedContainer(
      duration: DesignTokens.animationNormal,
      width: double.infinity,
      height: DesignTokens.buttonHeight,
      curve: Curves.easeOut,
      child: ElevatedButton(
        onPressed: isLoading 
            ? null 
            : () {
                HapticFeedback.selectionClick();
                onPressed();
              },
        style: _getButtonStyle(colorScheme),
        child: AnimatedSwitcher(
          duration: DesignTokens.animationFast,
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: animation.drive(
                  Tween<double>(begin: 0.95, end: 1.0).chain(
                    CurveTween(curve: Curves.easeOutCubic),
                  ),
                ),
                child: child,
              ),
            );
          },
          child: isLoading
              ? _loadingIndicator(colorScheme)
              : Row(
                  key: const ValueKey('button-content'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(
                        icon,
                        color: _getTextColor(colorScheme),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      text,
                      style: DesignTokens.labelMedium.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _getTextColor(colorScheme),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  ButtonStyle _getButtonStyle(ColorScheme colorScheme) {
    switch (type) {
      case AuthButtonType.primary:
        return ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          disabledBackgroundColor: colorScheme.primary.withOpacity(0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: DesignTokens.m),
        );
      case AuthButtonType.secondary:
        return ElevatedButton.styleFrom(
          backgroundColor: colorScheme.secondary,
          foregroundColor: colorScheme.onSecondary,
          disabledBackgroundColor: colorScheme.secondary.withOpacity(0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: DesignTokens.m),
        );
      case AuthButtonType.outline:
        return ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: colorScheme.primary,
          disabledBackgroundColor: Colors.transparent,
          disabledForegroundColor: colorScheme.primary.withOpacity(0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
            side: BorderSide(
              color: colorScheme.primary,
              width: 1.5,
            ),
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: DesignTokens.m),
        );
    }
  }

  Color _getTextColor(ColorScheme colorScheme) {
    switch (type) {
      case AuthButtonType.primary:
      case AuthButtonType.secondary:
        return colorScheme.onPrimary;
      case AuthButtonType.outline:
        return colorScheme.primary;
    }
  }

  Widget _loadingIndicator(ColorScheme colorScheme) {
    return SizedBox(
      key: const ValueKey('loading-indicator'),
      width: 24,
      height: 24,
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        valueColor: AlwaysStoppedAnimation<Color>(
          type == AuthButtonType.outline
              ? colorScheme.primary
              : colorScheme.onPrimary,
        ),
      ),
    );
  }
}