import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_form_field.dart';
import '../widgets/auth_header.dart';
import '../../../utils/validators.dart';
import '../../../widgets/loading_overlay.dart';
import '../../../constants/design_tokens.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: DesignTokens.animationSlow,
    );
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    FocusScope.of(context).unfocus();
    
    if (_formKey.currentState?.validate() ?? false) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Clear previous errors
      if (authProvider.errorMessage != null) {
        authProvider.clearError();
      }
      
      final success = await authProvider.resetPassword(_emailController.text.trim());

      if (success && mounted) {
        setState(() {
          _emailSent = true;
        });
        _animationController.forward();
      } else if (mounted) {
        // Show error as a snackbar instead of inside form
        if (authProvider.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authProvider.errorMessage!),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(DesignTokens.m),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isLoading = authProvider.status == AuthStatus.authenticating;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.onBackground),
      ),
      body: LoadingOverlay(
        isLoading: isLoading,
        child: SafeArea(
          child: Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxWidth = constraints.maxWidth > 600 ? 450.0 : constraints.maxWidth;
                
                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: DesignTokens.l,
                    vertical: DesignTokens.m,
                  ),
                  child: Center(
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: maxWidth,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const AuthHeader(
                            title: 'Reset Password',
                            subtitle: 'Enter your email, and we\'ll send you instructions to reset your password',
                          ),
                          
                          if (_emailSent)
                            _buildSuccessMessage(colorScheme)
                          else
                            _buildResetForm(authProvider, isLoading, colorScheme),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessMessage(ColorScheme colorScheme) {
    return FadeTransition(
      opacity: _fadeInAnimation,
      child: Card(
        color: colorScheme.surfaceVariant,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        ),
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.l),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Lottie.asset(
                'assets/animations/email_sent.json',
                width: 120,
                height: 120,
                repeat: false,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.mark_email_read,
                  size: 64,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: DesignTokens.m),
              Text(
                'Reset Instructions Sent',
                style: DesignTokens.titleMedium.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: DesignTokens.m),
              Text(
                'We\'ve sent password reset instructions to ${_emailController.text}',
                textAlign: TextAlign.center,
                style: DesignTokens.bodyMedium.copyWith(
                  color: colorScheme.onSurfaceVariant.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: DesignTokens.l),
              AuthButton(
                text: 'Back to Login',
                onPressed: () {
                  Navigator.pop(context);
                },
                type: AuthButtonType.primary,
              ),
              const SizedBox(height: DesignTokens.m),
              TextButton(
                onPressed: () {
                  setState(() {
                    _emailSent = false;
                  });
                  _animationController.reset();
                },
                child: Text(
                  'Didn\'t receive the email? Try again',
                  style: DesignTokens.bodyMedium.copyWith(
                    color: colorScheme.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResetForm(AuthProvider authProvider, bool isLoading, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Reset password form
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Email field
              AuthFormField(
                label: 'Email',
                hintText: 'Enter your email',
                controller: _emailController,
                validator: Validators.validateEmail,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _handleResetPassword(),
                prefixIcon: Icons.email_rounded,
                autofillHints: const [AutofillHints.email],
              ),
              const SizedBox(height: DesignTokens.xl),
              
              // Reset button
              AuthButton(
                text: 'Send Reset Instructions',
                onPressed: _handleResetPassword,
                isLoading: isLoading,
              ),
              const SizedBox(height: DesignTokens.m),
              
              // Back to login
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Back to Login',
                    style: DesignTokens.bodyMedium.copyWith(
                      color: colorScheme.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}