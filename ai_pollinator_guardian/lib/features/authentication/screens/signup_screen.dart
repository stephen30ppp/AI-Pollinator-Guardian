import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_form_field.dart';
import '../widgets/auth_header.dart';
import '../../../utils/validators.dart';

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
  bool _isSigningUp = false; // Track the entire signup process
  String? _usernameError;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    
    _usernameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _showPassword = !_showPassword;
    });
  }

  void _toggleConfirmPasswordVisibility() {
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
      final success = await authProvider.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        username: _usernameController.text.trim(),
      );

      // Only remove loading state after showing the success dialog or if there was an error
      if (success && mounted) {
        // Show success dialog and navigate to home
        _showSignupSuccessDialog();
      } else {
        // In case of error, reset the loading state
        setState(() {
          _isSigningUp = false;
        });
      }
    }
  }

  void _showSignupSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.green),
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

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    // Use _isSigningUp OR the authenticating status to disable the button
    final isLoading = _isSigningUp || authProvider.status == AuthStatus.authenticating;
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AuthHeader(
                title: 'Create Account',
                subtitle: 'Join our community to help protect pollinators',
              ),
              
              // Error message (if any)
              if (authProvider.errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          authProvider.errorMessage!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                    ],
                  ),
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
                      suffixIcon: _isUsernameChecking
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(height: 20),
                    
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
                    ),
                    const SizedBox(height: 20),
                    
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
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.grey,
                        size: 20,
                      ),
                      onTapSuffix: _togglePasswordVisibility,
                    ),
                    const SizedBox(height: 20),
                    
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
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.grey,
                        size: 20,
                      ),
                      onTapSuffix: _toggleConfirmPasswordVisibility,
                    ),
                    const SizedBox(height: 24),
                    
                    // Terms and conditions text
                    Text(
                      'By signing up, you agree to our Terms of Service and Privacy Policy',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Signup button
                    AuthButton(
                      text: 'Create Account',
                      onPressed: _handleSignup,
                      isLoading: isLoading,
                    ),
                    const SizedBox(height: 16),
                    
                    // Already have account
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: RichText(
                          text: const TextSpan(
                            text: 'Already have an account? ',
                            style: TextStyle(color: Colors.black87, fontSize: 14),
                            children: [
                              TextSpan(
                                text: 'Sign in',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}