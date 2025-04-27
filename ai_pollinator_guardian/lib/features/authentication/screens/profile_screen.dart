import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/design_tokens.dart';
import '../../../services/storage_service.dart';
import '../../../widgets/loading_overlay.dart';
import '../../../widgets/error_banner.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_button.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _nameInitialValue = TextEditingController();
  final _usernameInitialValue = TextEditingController();
  
  final StorageService _storageService = StorageService();
  
  File? _profileImage;
  bool _isLoading = false;
  bool _hasChanges = false;
  String? _usernameError;
  
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    // Animation setup
    _animationController = AnimationController(
      vsync: this,
      duration: DesignTokens.animationNormal,
    );
    
    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
    
    _initializeUserData();
    
    // Listen for changes to enable/disable save button
    _nameController.addListener(_checkForChanges);
    _usernameController.addListener(_checkForChanges);
  }

  @override
  void dispose() {
    _nameController.removeListener(_checkForChanges);
    _usernameController.removeListener(_checkForChanges);
    
    _nameController.dispose();
    _usernameController.dispose();
    _nameInitialValue.dispose();
    _usernameInitialValue.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _initializeUserData() {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user != null) {
      _nameController.text = user.name;
      _usernameController.text = user.username;
      
      // Store initial values to detect changes
      _nameInitialValue.text = user.name;
      _usernameInitialValue.text = user.username;
    }
  }

  void _checkForChanges() {
    final hasNameChanged = _nameController.text != _nameInitialValue.text;
    final hasUsernameChanged = _usernameController.text != _usernameInitialValue.text;
    
    final newHasChanges = hasNameChanged || hasUsernameChanged || _profileImage != null;
    
    if (newHasChanges != _hasChanges) {
      setState(() {
        _hasChanges = newHasChanges;
      });
      
      if (_hasChanges && !_animationController.isCompleted) {
        _animationController.forward();
      } else if (!_hasChanges && _animationController.isCompleted) {
        _animationController.reverse();
      }
    }
  }

  Future<void> _pickImage() async {
    HapticFeedback.selectionClick();
    
    final image = await _storageService.pickImage(imageQuality: 85);
    if (image != null) {
      setState(() {
        _profileImage = image;
        _hasChanges = true;
      });
      _animationController.forward();
    }
  }

  Future<bool> _validateUsername(String username) async {
    if (username.isEmpty) {
      setState(() {
        _usernameError = 'Username cannot be empty';
      });
      return false;
    }

    if (username.length < 3) {
      setState(() {
        _usernameError = 'Username must be at least 3 characters';
      });
      return false;
    }

    if (username.length > 20) {
      setState(() {
        _usernameError = 'Username must be at most 20 characters';
      });
      return false;
    }

    // Only allow letters, numbers, and underscores
    final RegExp usernameRegex = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!usernameRegex.hasMatch(username)) {
      setState(() {
        _usernameError = 'Username can only contain letters, numbers, and underscores';
      });
      return false;
    }

    // Check if username is already taken (only if changed)
    final currentUser = Provider.of<AuthProvider>(context, listen: false).user;
    if (currentUser != null && username.toLowerCase() != currentUser.username.toLowerCase()) {
      final isAvailable = await Provider.of<AuthProvider>(context, listen: false)
          .isUsernameAvailable(username);
      
      if (!isAvailable) {
        setState(() {
          _usernameError = 'This username is already taken';
        });
        return false;
      }
    }

    setState(() {
      _usernameError = null;
    });
    return true;
  }

  Future<void> _updateProfile() async {
    // Validate form
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    
    // Validate username
    final isUsernameValid = await _validateUsername(_usernameController.text.trim());
    if (!isUsernameValid) return;

    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    
    if (user == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    String? photoUrl;
    
    // Upload profile image if changed
    if (_profileImage != null) {
      try {
        photoUrl = await _storageService.uploadFile(
          file: _profileImage!,
          folder: 'users/${user.id}/profile',
          fileName: 'profile.jpg',
        );
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ErrorBanner.showErrorSnackBar(context, message: 'Failed to upload image: $e');
          return;
        }
      }
    }

    // Update user profile
    final success = await authProvider.updateProfile(
      displayName: _nameController.text.trim(),
      username: _usernameController.text.trim(),
      photoUrl: photoUrl,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }

    if (success && mounted) {
      _animationController.reverse();
      
      // Update initial values after successful update
      _nameInitialValue.text = _nameController.text;
      _usernameInitialValue.text = _usernameController.text;
      
      setState(() {
        _hasChanges = false;
        _profileImage = null;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: DesignTokens.s),
              Text('Profile updated successfully'),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(DesignTokens.m),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _confirmSignOut() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _signOut();
            },
            child: const Text('SIGN OUT'),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut() async {
    setState(() {
      _isLoading = true;
    });
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.signOut();
    
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    if (user == null) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        actions: [
          // Add a help button
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            onPressed: () {
              // Show a simple help dialog
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Profile Help'),
                  content: const Text(
                    'This is your profile page where you can update your display name, username, and profile picture. '
                    'Your activity statistics are shown at the bottom.'
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('GOT IT'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(DesignTokens.l),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: DesignTokens.m),
                    
                    // Profile picture
                    _buildProfilePicture(user.photoUrl, colorScheme),
                    const SizedBox(height: DesignTokens.xl),
                    
                    // User info
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Profile Information',
                        style: DesignTokens.titleMedium.copyWith(
                          color: colorScheme.onBackground,
                        ),
                      ),
                    ),
                    const SizedBox(height: DesignTokens.m),
                    
                    // Display name field
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Display Name',
                        hintText: 'Enter your display name',
                        prefixIcon: const Icon(Icons.person_rounded),
                      ),
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Display name is required';
                        }
                        if (value.trim().length < 2) {
                          return 'Display name must be at least 2 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: DesignTokens.m),
                    
                    // Username field
                    TextFormField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: 'Username',
                        hintText: 'Enter your username',
                        prefixIcon: const Icon(Icons.alternate_email_rounded),
                        errorText: _usernameError,
                      ),
                      textInputAction: TextInputAction.done,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Username is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: DesignTokens.m),
                    
                    // Email (disabled)
                    TextFormField(
                      enabled: false,
                      initialValue: user.email,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        hintText: user.email,
                        prefixIcon: const Icon(Icons.email_rounded),
                        filled: true,
                        fillColor: colorScheme.surfaceVariant.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: DesignTokens.xl),
                    
                    // Divider
                    const Divider(height: DesignTokens.m),
                    const SizedBox(height: DesignTokens.m),
                    
                    // Activity statistics section
                    _buildStatisticsSection(user, colorScheme),
                    const SizedBox(height: DesignTokens.xl),
                    
                    // Sign out button
                    AuthButton(
                      text: 'Sign Out',
                      onPressed: _confirmSignOut,
                      type: AuthButtonType.outline,
                      icon: Icons.logout_rounded,
                    ),
                    const SizedBox(height: DesignTokens.m),
                  ],
                ),
              ),
            ),
            
            // Floating Save Button - Only appears when changes are made
            Positioned(
              bottom: DesignTokens.l,
              right: DesignTokens.l,
              child: AnimatedBuilder(
                animation: _slideAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, 100 * (1 - _slideAnimation.value)),
                    child: Opacity(
                      opacity: _slideAnimation.value,
                      child: child,
                    ),
                  );
                },
                child: FloatingActionButton.extended(
                  onPressed: _hasChanges ? _updateProfile : null,
                  backgroundColor: _hasChanges 
                      ? colorScheme.primary 
                      : colorScheme.surfaceVariant,
                  foregroundColor: _hasChanges 
                      ? colorScheme.onPrimary 
                      : colorScheme.onSurfaceVariant.withOpacity(0.5),
                  elevation: 4,
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('Save Changes'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePicture(String? photoUrl, ColorScheme colorScheme) {
    return Stack(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colorScheme.surfaceVariant,
            border: Border.all(
              color: colorScheme.primary,
              width: 3,
            ),
            image: _profileImage != null
                ? DecorationImage(
                    image: FileImage(_profileImage!),
                    fit: BoxFit.cover,
                  )
                : photoUrl != null
                    ? DecorationImage(
                        image: NetworkImage(photoUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
          ),
          child: photoUrl == null && _profileImage == null
              ? Icon(
                  Icons.person_rounded,
                  size: 64,
                  color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                )
              : null,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Material(
            color: colorScheme.primary,
            shape: const CircleBorder(
              side: BorderSide(color: Colors.white, width: 2),
            ),
            elevation: 4,
            child: InkWell(
              onTap: _pickImage,
              customBorder: const CircleBorder(),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.camera_alt_rounded,
                  color: colorScheme.onPrimary,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsSection(dynamic user, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Activity',
          style: DesignTokens.titleMedium.copyWith(
            color: colorScheme.onBackground,
          ),
        ),
        const SizedBox(height: DesignTokens.m),
        Row(
          children: [
            _buildStatCard(
              'Pollinator Sightings',
              user.sightings.length.toString(),
              Icons.visibility_rounded,
              colorScheme,
            ),
            const SizedBox(width: DesignTokens.m),
            _buildStatCard(
              'Gardens',
              user.gardens.length.toString(),
              Icons.local_florist_rounded,
              colorScheme,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, ColorScheme colorScheme) {
    return Expanded(
      child: Card(
        color: colorScheme.secondaryContainer,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        ),
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: colorScheme.secondary,
                size: 24,
              ),
              const SizedBox(height: DesignTokens.s),
              Text(
                value,
                style: DesignTokens.titleLarge.copyWith(
                  fontSize: 20,
                  color: colorScheme.onSecondaryContainer,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: DesignTokens.bodyMedium.copyWith(
                  color: colorScheme.onSecondaryContainer.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}