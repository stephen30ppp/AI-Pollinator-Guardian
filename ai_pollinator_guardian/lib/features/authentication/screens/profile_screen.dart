import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../constants/app_colors.dart';
import '../../../services/storage_service.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_button.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final StorageService _storageService = StorageService();
  File? _profileImage;
  bool _isLoading = false;
  String? _usernameError;

  @override
  void initState() {
    super.initState();
    _initializeUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  void _initializeUserData() {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user != null) {
      _nameController.text = user.name;
      _usernameController.text = user.username;
    }
  }

  Future<void> _pickImage() async {
    final image = await _storageService.pickImage();
    if (image != null) {
      setState(() {
        _profileImage = image;
      });
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to upload image: $e')),
          );
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }
    }

    // Update user profile
    final success = await authProvider.updateProfile(
      displayName: _nameController.text.trim(),
      username: _usernameController.text.trim(),
      photoUrl: photoUrl,
    );

    setState(() {
      _isLoading = false;
    });

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    }
  }

  Future<void> _signOut() async {
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
    
    if (user == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            
            // Profile picture
            _buildProfilePicture(user.photoUrl),
            const SizedBox(height: 24),
            
            // User info
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Profile Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Display name field
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Display Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: const Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            
            // Username field
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: const Icon(Icons.alternate_email),
                errorText: _usernameError,
              ),
            ),
            const SizedBox(height: 16),
            
            // Email (disabled)
            TextField(
              enabled: false,
              controller: TextEditingController(text: user.email),
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: const Icon(Icons.email),
                fillColor: Colors.grey.shade200,
                filled: true,
              ),
            ),
            const SizedBox(height: 32),
            
            // Update profile button
            AuthButton(
              text: 'Update Profile',
              isLoading: _isLoading,
              onPressed: _updateProfile,
            ),
            const SizedBox(height: 16),
            
            // Divider
            const Divider(height: 32),
            
            // Activity statistics section
            _buildStatisticsSection(user),
            const SizedBox(height: 24),
            
            // Sign out button
            AuthButton(
              text: 'Sign Out',
              onPressed: _signOut,
              type: AuthButtonType.outline,
              icon: Icons.logout,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePicture(String? photoUrl) {
    return Stack(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey.shade200,
            border: Border.all(
              color: AppColors.primaryColor,
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
              ? const Icon(
                  Icons.person,
                  size: 64,
                  color: Colors.grey,
                )
              : null,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsSection(dynamic user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Activity',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildStatCard(
              'Pollinator Sightings',
              user.sightings.length.toString(),
              Icons.visibility,
            ),
            const SizedBox(width: 16),
            _buildStatCard(
              'Gardens',
              user.gardens.length.toString(),
              Icons.local_florist,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: AppColors.primaryColor,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}