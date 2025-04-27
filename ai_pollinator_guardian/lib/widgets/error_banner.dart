import 'package:flutter/material.dart';
import '../constants/design_tokens.dart';

/// A reusable error banner component for displaying errors
/// in a consistent manner throughout the app.
class ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onDismiss;
  final bool isDismissible;
  final EdgeInsets padding;
  final double? width;

  const ErrorBanner({
    Key? key,
    required this.message,
    this.onDismiss,
    this.isDismissible = true,
    this.padding = const EdgeInsets.all(12),
    this.width,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: width,
      margin: const EdgeInsets.only(bottom: DesignTokens.m),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: padding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: colorScheme.error,
                size: 20,
              ),
              const SizedBox(width: DesignTokens.s),
              Expanded(
                child: Text(
                  message,
                  style: DesignTokens.bodyMedium.copyWith(
                    color: colorScheme.onErrorContainer,
                  ),
                ),
              ),
              if (isDismissible && onDismiss != null)
                InkWell(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusCircular),
                  onTap: onDismiss,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.close_rounded,
                      color: colorScheme.onErrorContainer,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Shows an error snackbar instead of an inline banner.
  /// Use this for transient errors or action-related feedback.
  static void showErrorSnackBar(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 4),
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: colorScheme.error,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        margin: const EdgeInsets.all(DesignTokens.m),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
        ),
        action: SnackBarAction(
          label: 'DISMISS',
          textColor: colorScheme.onError,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}