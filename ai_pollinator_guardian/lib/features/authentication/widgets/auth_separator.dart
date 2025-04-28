import 'package:flutter/material.dart';
import '../../../constants/design_tokens.dart';

class AuthSeparator extends StatelessWidget {
  final String text;
  
  const AuthSeparator({
    Key? key,
    this.text = 'OR',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: colorScheme.outline.withOpacity(0.5),
            thickness: 0.8,
            indent: 8,
            endIndent: 8,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.m),
          child: Opacity(
            opacity: 0.6,
            child: Text(
              text,
              style: DesignTokens.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: colorScheme.outline.withOpacity(0.5),
            thickness: 0.8,
            indent: 8,
            endIndent: 8,
          ),
        ),
      ],
    );
  }
}