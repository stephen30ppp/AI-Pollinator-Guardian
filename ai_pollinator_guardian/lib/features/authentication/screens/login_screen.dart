import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_form_field.dart';
import '../widgets/auth_separator.dart';
import '../widgets/auth_header.dart';
import '../../../utils/validators.dart';
import '../../../widgets/loading_overlay.dart';
import '../../../constants/design_tokens.dart';
import 'forgot_password_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailOrUsernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailOrUsernameFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  bool _showPassword = false;

  @override
  void dispose() {
    _emailOrUsernameController.dispose();
    _passwordController.dispose();
    _emailOrUsernameFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    HapticFeedback.selectionClick();
    setState(() {
      _showPassword = !_showPassword;
    });
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();
    
    if (_formKey.currentState?.validate() ?? false) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Clear previous errors
      if (authProvider.errorMessage != null) {
        authProvider.clearError();
      }
      
      final success = await authProvider.signIn(
        emailOrUsername: _emailOrUsernameController.text.trim(),
        password: _passwordController.text,
      );

      if (success && mounted) {
        // Redirect to home screen on successful login
        Navigator.pushReplacementNamed(context, '/');
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
                            title: 'Welcome Back!',
                            subtitle: 'Sign in to continue your journey with the pollinators',
                          ),
                          
                          // Login form
                          Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Email or Username field
                                AuthFormField(
                                  label: 'Email or Username',
                                  hintText: 'Enter your email or username',
                                  controller: _emailOrUsernameController,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Email or username is required';
                                    }
                                    return null;
                                  },
                                  keyboardType: TextInputType.emailAddress,
                                  focusNode: _emailOrUsernameFocusNode,
                                  textInputAction: TextInputAction.next,
                                  onFieldSubmitted: (_) {
                                    FocusScope.of(context).requestFocus(_passwordFocusNode);
                                  },
                                  prefixIcon: Icons.alternate_email_rounded,
                                  autofillHints: const [
                                    AutofillHints.email,
                                    AutofillHints.username,
                                  ],
                                ),
                                const SizedBox(height: DesignTokens.l),
                                
                                // Password field
                                AuthFormField(
                                  label: 'Password',
                                  hintText: 'Enter your password',
                                  controller: _passwordController,
                                  obscureText: !_showPassword,
                                  validator: Validators.validatePassword,
                                  focusNode: _passwordFocusNode,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _handleLogin(),
                                  suffixIcon: Icon(
                                    _showPassword
                                        ? Icons.visibility_off_rounded
                                        : Icons.visibility_rounded,
                                    color: colorScheme.onSurfaceVariant,
                                    size: 20,
                                  ),
                                  onTapSuffix: _togglePasswordVisibility,
                                  prefixIcon: Icons.lock_rounded,
                                  autofillHints: const [AutofillHints.password],
                                ),
                                const SizedBox(height: DesignTokens.m),
                                
                                // Forgot password link
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const ForgotPasswordScreen(),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      'Forgot Password?',
                                      style: DesignTokens.bodyMedium.copyWith(
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: DesignTokens.l),
                                
                                // Login button
                                AuthButton(
                                  text: 'Sign In',
                                  onPressed: _handleLogin,
                                  isLoading: isLoading,
                                ),
                                const SizedBox(height: DesignTokens.xl),
                                
                                // OR separator
                                const AuthSeparator(),
                                const SizedBox(height: DesignTokens.xl),
                                
                                // Create account button
                                AuthButton(
                                  text: 'Create an Account',
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const SignupScreen(),
                                      ),
                                    );
                                  },
                                  type: AuthButtonType.outline,
                                ),
                              ],
                            ),
                          ),
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
}