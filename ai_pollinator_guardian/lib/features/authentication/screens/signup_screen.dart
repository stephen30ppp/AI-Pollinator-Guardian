import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_form_field.dart';
import '../widgets/auth_header.dart';
import '../../../utils/validators.dart';
import '../../../widgets/loading_overlay.dart';
import '../../../constants/design_tokens.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  final _usernameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();
  
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _isUsernameChecking = false;
  bool _isSigningUp = false;
  String? _usernameError;
  bool _isUsernameValid = false;

  @override
  void initState() {
    super.initState();
    _usernameFocusNode.addListener(_onUsernameFocusChange);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    
    _usernameFocusNode.removeListener(_onUsernameFocusChange);
    _usernameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    
    super.dispose();
  }

  void _onUsernameFocusChange() {
    // When username field loses focus, check if it's valid
    if (!_usernameFocusNode.hasFocus) {
      _checkUsernameAvailability();
    }
  }

  Future<void> _checkUsernameAvailability() async {
    final username = _usernameController.text.trim();
    
    // Basic validation first
    if (username.length < 3) return;
    
    setState(() {
      _isUsernameChecking = true;
      _usernameError = null; // Clear previous errors
    });
    
    try {
      final isAvailable = await Provider.of<AuthProvider>(context, listen: false)
          .isUsernameAvailable(username);
      
      setState(() {
        _isUsernameChecking = false;
        _isUsernameValid = isAvailable;
        if (!isAvailable) {
          _usernameError = 'This username is already taken';
        }
      });
    } catch (e) {
      setState(() {
        _isUsernameChecking = false;
        _usernameError = 'Could not check username availability';
      });
    }
  }

  void _togglePasswordVisibility() {
    HapticFeedback.selectionClick();
    setState(() {
      _showPassword = !_showPassword;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    HapticFeedback.selectionClick();
    setState(() {
      _showConfirmPassword = !_showConfirmPassword;
    });
  }

  // Validate that password and confirm password match
  String? _validateConfirmPassword(String? value) {
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  // Validate username format
  String? _validateUsername(String? value) {
    if (_usernameError != null) {
      return _usernameError;
    }
    
    if (value == null || value.trim().isEmpty) {
      return 'Username is required';
    }
    
    if (value.length < 3) {
      return 'Username must be at least 3 characters';
    }
    
    if (value.length > 20) {
      return 'Username must be at most 20 characters';
    }
    
    // Only allow letters, numbers, and underscores
    final RegExp usernameRegex = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!usernameRegex.hasMatch(value)) {
      return 'Username can only contain letters, numbers, and underscores';
    }
    
    return null;
  }

  Future<void> _handleSignup() async {
    FocusScope.of(context).unfocus();
    
    // Reset username error
    setState(() {
      _usernameError = null;
    });
    
    if (_formKey.currentState?.validate() ?? false) {
      // Set loading state manually to prevent button from being clickable
      setState(() {
        _isSigningUp = true;
      });
      
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Clear previous errors
      if (authProvider.errorMessage != null) {
        authProvider.clearError();
      }
      
      final success = await authProvider.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        username: _usernameController.text.trim(),
      );

      // Only remove loading state after showing the success dialog or if there was an error
      if (success && mounted) {
        // Show success dialog and navigate to home
        _showSignupSuccessDialog();
      } else if (mounted) {
        // In case of error, reset the loading state
        setState(() {
          _isSigningUp = false;
        });
        
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

  void _showSignupSuccessDialog() {
    final colorScheme = Theme.of(context).colorScheme;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check, color: colorScheme.primary),
            ),
            const SizedBox(width: 16),
            const Text('Account Created'),
          ],
        ),
        content: const Text(
          'Your account has been created successfully. A verification email has been sent to your email address.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pushReplacementNamed(context, '/'); // Go to home
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Widget _buildUsernameStatus() {
    if (_isUsernameChecking) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
        ),
      );
    }
    
    if (_isUsernameValid) {
      return Icon(
        Icons.check_circle_rounded,
        color: Colors.green.shade600,
        size: 20,
      );
    }
    
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    // Use _isSigningUp OR the authenticating status to disable the button
    final isLoading = _isSigningUp || authProvider.status == AuthStatus.authenticating;
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
                            title: 'Create Account',
                            subtitle: 'Join our community to help protect pollinators',
                          ),
                          
                          // Signup form
                          Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Username field
                                AuthFormField(
                                  label: 'Username',
                                  hintText: 'Choose a unique username',
                                  controller: _usernameController,
                                  validator: _validateUsername,
                                  focusNode: _usernameFocusNode,
                                  textInputAction: TextInputAction.next,
                                  onFieldSubmitted: (_) {
                                    FocusScope.of(context).requestFocus(_emailFocusNode);
                                  },
                                  suffixIcon: _buildUsernameStatus(),
                                  prefixIcon: Icons.person_rounded,
                                  autofillHints: const [AutofillHints.username],
                                ),
                                const SizedBox(height: DesignTokens.l),
                                
                                // Email field
                                AuthFormField(
                                  label: 'Email',
                                  hintText: 'Enter your email',
                                  controller: _emailController,
                                  validator: Validators.validateEmail,
                                  keyboardType: TextInputType.emailAddress,
                                  focusNode: _emailFocusNode,
                                  textInputAction: TextInputAction.next,
                                  onFieldSubmitted: (_) {
                                    FocusScope.of(context).requestFocus(_passwordFocusNode);
                                  },
                                  prefixIcon: Icons.email_rounded,
                                  autofillHints: const [AutofillHints.email],
                                ),
                                const SizedBox(height: DesignTokens.l),
                                
                                // Password field
                                AuthFormField(
                                  label: 'Password',
                                  hintText: 'Create a password',
                                  controller: _passwordController,
                                  obscureText: !_showPassword,
                                  validator: Validators.validatePassword,
                                  focusNode: _passwordFocusNode,
                                  textInputAction: TextInputAction.next,
                                  onFieldSubmitted: (_) {
                                    FocusScope.of(context).requestFocus(_confirmPasswordFocusNode);
                                  },
                                  suffixIcon: Icon(
                                    _showPassword
                                        ? Icons.visibility_off_rounded
                                        : Icons.visibility_rounded,
                                    color: colorScheme.onSurfaceVariant,
                                    size: 20,
                                  ),
                                  onTapSuffix: _togglePasswordVisibility,
                                  prefixIcon: Icons.lock_rounded,
                                  autofillHints: const [AutofillHints.newPassword],
                                ),
                                const SizedBox(height: DesignTokens.l),
                                
                                // Confirm Password field
                                AuthFormField(
                                  label: 'Confirm Password',
                                  hintText: 'Confirm your password',
                                  controller: _confirmPasswordController,
                                  obscureText: !_showConfirmPassword,
                                  validator: (value) {
                                    final passwordValidation = Validators.validatePassword(value);
                                    if (passwordValidation != null) {
                                      return passwordValidation;
                                    }
                                    return _validateConfirmPassword(value);
                                  },
                                  focusNode: _confirmPasswordFocusNode,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _handleSignup(),
                                  suffixIcon: Icon(
                                    _showConfirmPassword
                                        ? Icons.visibility_off_rounded
                                        : Icons.visibility_rounded,
                                    color: colorScheme.onSurfaceVariant,
                                    size: 20,
                                  ),
                                  onTapSuffix: _toggleConfirmPasswordVisibility,
                                  prefixIcon: Icons.lock_rounded,
                                  autofillHints: const [AutofillHints.newPassword],
                                ),
                                const SizedBox(height: DesignTokens.m),
                                
                                // Terms and conditions text
                                Container(
                                  padding: const EdgeInsets.all(DesignTokens.m),
                                  decoration: BoxDecoration(
                                    color: colorScheme.secondaryContainer.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                                  ),
                                  child: Text(
                                    'By signing up, you agree to our Terms of Service and Privacy Policy',
                                    style: DesignTokens.bodyMedium.copyWith(
                                      color: colorScheme.onSecondaryContainer,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(height: DesignTokens.l),
                                
                                // Signup button
                                AuthButton(
                                  text: 'Create Account',
                                  onPressed: _handleSignup,
                                  isLoading: isLoading,
                                ),
                                const SizedBox(height: DesignTokens.m),
                                
                                // Already have account
                                Center(
                                  child: TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: RichText(
                                      text: TextSpan(
                                        text: 'Already have an account? ',
                                        style: DesignTokens.bodyMedium.copyWith(
                                          color: colorScheme.onBackground,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: 'Sign in',
                                            style: TextStyle(
                                              color: colorScheme.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: DesignTokens.m),
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