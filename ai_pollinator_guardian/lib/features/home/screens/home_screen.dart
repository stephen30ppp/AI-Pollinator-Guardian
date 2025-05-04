import 'package:ai_pollinator_guardian/features/home/widgets/activity_stat_card.dart';
import 'package:ai_pollinator_guardian/features/home/widgets/set_target_dialog.dart';
import 'package:ai_pollinator_guardian/services/TargetService.dart';
import 'package:ai_pollinator_guardian/services/sighting_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:ai_pollinator_guardian/features/authentication/providers/auth_provider.dart';
import 'package:ai_pollinator_guardian/features/home/widgets/avatar_glow.dart';
import 'package:ai_pollinator_guardian/features/home/widgets/fact_carousel.dart';
import 'package:ai_pollinator_guardian/features/home/widgets/feature_card_carousel.dart';
import 'package:ai_pollinator_guardian/features/home/widgets/story_activity.dart';
import 'package:ai_pollinator_guardian/widgets/bottom_navigation_bar.dart';
import 'package:ai_pollinator_guardian/constants/app_colors.dart';
import 'package:ai_pollinator_guardian/constants/design_tokens.dart';
import 'package:ai_pollinator_guardian/models/user_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late ScrollController _scrollController;
  final SightingService _sightingService = SightingService();

  // Animation controllers
  late AnimationController _statsFadeController;
  late Animation<double> _fadeInAnimation;
  late AnimationController _expandIconController;

  // State for activity section expansion
  bool _isActivityExpanded = true; // Set to true initially to show cards
  
  // Target values with defaults
  int _sightingsTarget = 10;
  int _speciesTarget = 5;
  int _gardensTarget = 3;
  
  // Activity stats
  int _sightingsCount = 0;
  int _speciesCount = 0;
  int _gardensCount = 0;
  
  // Loading states
  bool _loadingTargets = true;
  bool _loadingStats = true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    // Initialize fade-in animation controller
    _statsFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeInAnimation = CurvedAnimation(
      parent: _statsFadeController,
      curve: Curves.easeOut,
    );

    // Initialize expand icon animation controller
    _expandIconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 1.0, // Start in expanded state (pointing up)
    );

    // Start the fade-in animation after a short delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _statsFadeController.forward();
      }
    });
    
    // Load user targets from Firebase
    _loadUserTargets();
    
    // Load activity stats
    _loadActivityStats();
  }
  
  // Load targets from Firebase
  Future<void> _loadUserTargets() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user?.id == null) return;
    
    setState(() => _loadingTargets = true);
    
    try {
      final targetService = TargetService();
      final userId = authProvider.user!.id;
      
      // Load targets in parallel
      final sightingsTarget = await targetService.getUserTarget(
        userId, 
        TargetService.SIGHTINGS_TARGET,
        defaultValue: 10
      );
      
      final speciesTarget = await targetService.getUserTarget(
        userId, 
        TargetService.SPECIES_TARGET,
        defaultValue: 5
      );
      
      final gardensTarget = await targetService.getUserTarget(
        userId, 
        TargetService.GARDENS_TARGET,
        defaultValue: 3
      );
      
      if (mounted) {
        setState(() {
          _sightingsTarget = sightingsTarget;
          _speciesTarget = speciesTarget;
          _gardensTarget = gardensTarget;
          _loadingTargets = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading targets: $e');
      if (mounted) {
        setState(() => _loadingTargets = false);
      }
    }
  }
  
  // Load activity stats from Firebase
  Future<void> _loadActivityStats() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user?.id == null) return;
    
    setState(() => _loadingStats = true);
    
    try {
      final userId = authProvider.user!.id;
      
      // Load stats in parallel
      final sightingsCount = await _sightingService.getSightingsCount(userId);
      final speciesCount = await _sightingService.getUniqueSpeciesCount(userId);
      
      // For now, use the gardens field from user model since we don't have a gardens subcollection
      // This should be updated later to use a proper gardens subcollection query
      final gardensCount = authProvider.user?.gardens?.length ?? 0;
      
      if (mounted) {
        setState(() {
          _sightingsCount = sightingsCount;
          _speciesCount = speciesCount;
          _gardensCount = gardensCount;
          _loadingStats = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading activity stats: $e');
      if (mounted) {
        setState(() => _loadingStats = false);
      }
    }
  }
  
  // Refresh all data
  Future<void> _refreshData() async {
    await Future.wait([
      _loadUserTargets(),
      _loadActivityStats(),
    ]);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _statsFadeController.dispose();
    _expandIconController.dispose();
    super.dispose();
  }

  void _toggleActivityExpansion() {
    HapticFeedback.lightImpact();
    setState(() {
      _isActivityExpanded = !_isActivityExpanded;
      if (_isActivityExpanded) {
        _expandIconController.forward();
      } else {
        _expandIconController.reverse();
      }
    });
  }

  // Show target setting dialog
  void _showSetTargetDialog(String targetType, int currentTarget) {
    SetTargetDialog.show(
      context,
      targetType: targetType,
      currentTarget: currentTarget,
      onTargetSet: (int newTarget) => _updateUserTarget(targetType, newTarget),
    );
  }

  // Update a user target in Firestore
  Future<void> _updateUserTarget(String targetType, int newTarget) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user?.id == null) return;
    
    final targetService = TargetService();
    final userId = authProvider.user!.id;
    
    // Update local state immediately for better UX
    setState(() {
      switch (targetType) {
        case TargetService.SIGHTINGS_TARGET:
          _sightingsTarget = newTarget;
          break;
        case TargetService.SPECIES_TARGET:
          _speciesTarget = newTarget;
          break;
        case TargetService.GARDENS_TARGET:
          _gardensTarget = newTarget;
          break;
      }
    });
    
    // Then update in Firestore
    try {
      await targetService.updateUserTarget(userId, targetType, newTarget);
    } catch (e) {
      debugPrint('Error updating target: $e');
      // Could show a snackbar here to notify of error
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: AppColors.primaryColor,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            // App Bar
            SliverAppBar(
              automaticallyImplyLeading: false,
              pinned: true,
              toolbarHeight: kToolbarHeight,
              titleSpacing: 16,
              title: const Text(
                'AI Pollinator Guardian',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              flexibleSpace: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryColor, AppColors.accentColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Hero(
                    tag: 'profileAvatar',
                    child: AvatarGlow(
                      imageUrl: user?.photoUrl,
                      showNotification: true,
                      onTap: () {
                        Navigator.pushNamed(context, '/profile');
                      },
                    ),
                  ),
                ),
              ],
            ),

            // Main content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: DesignTokens.m),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Fact Carousel
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.l),
                      child: FactCardCarousel(
                        facts: PollinatorFact.sampleFacts,
                        greeting: 'Good Day, Nature Guardian!',
                      ),
                    ),
                    const SizedBox(height: DesignTokens.l),

                    // Feature Cards Carousel
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s),
                      child: FeatureCardCarousel(
                        items: [
                          FeatureCardItem(
                            title: 'Identify Pollinators',
                            description: 'Snap a photo to reveal the secret lives of bees & butterflies.',
                            imagePath: 'assets/images/identify_pollinators.jpg',
                            onTap: () => Navigator.pushNamed(context, '/identify'),
                          ),
                          FeatureCardItem(
                            title: 'Garden Scanner',
                            description: 'Analyze your garden and get custom pollinator tips.',
                            imagePath: 'assets/images/garden_scanner.jpg',
                            onTap: () => Navigator.pushNamed(context, '/garden'),
                          ),
                          FeatureCardItem(
                            title: 'Community Map',
                            description: 'Explore pollinator sightings in your area.',
                            imagePath: 'assets/images/map.jpg',
                            onTap: () => Navigator.pushNamed(context, '/map'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: DesignTokens.xl),

                    // Your Activity section - with consistent styling to Recent Activity
                    _buildSectionHeader(
                      title: 'Your Activity',
                      actionWidget: _buildSectionAction(
                        label: _isActivityExpanded ? 'Collapse' : 'Expand',
                        trailing: const Icon(Icons.expand_more, size: 12),
                        rotateTrailing: true,
                        onPressed: _toggleActivityExpansion,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.s),

                    // Activity Cards - Show/hide based on expanded state
                    AnimatedCrossFade(
                      firstChild: _buildActivityCards(),
                      secondChild: const SizedBox(height: 0),
                      crossFadeState: _isActivityExpanded 
                          ? CrossFadeState.showFirst 
                          : CrossFadeState.showSecond,
                      duration: const Duration(milliseconds: 300),
                    ),
                    const SizedBox(height: DesignTokens.xl),

                    // Recent Activity section
                    _buildSectionHeader(
                      title: 'Recent Activity',
                      actionWidget: _buildSectionAction(
                        label: 'View all',
                        onPressed: () => Navigator.pushNamed(context, '/history'),
                      ),
                    ),
                    const SizedBox(height: DesignTokens.s),

                    // Story items
                    SizedBox(
                      height: 110,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: DesignTokens.m),
                        children: [ 
                          StoryItem(
                            title: 'Bumblebee', date: 'Today', imagePath: 'assets/images/bumblebee.jpg', onTap: () {},
                          ),
                          StoryItem(
                            title: 'Monarch', date: 'Yesterday', imagePath: 'assets/images/monarch.jpg', onTap: () {},
                          ),
                          StoryItem(
                            title: 'Garden Scan', date: '2 days ago', imagePath: 'assets/images/garden.jpg', onTap: () {},
                          ),
                          StoryItem(
                            title: 'Honeybee', date: '3 days ago', imagePath: 'assets/images/honeybee.jpg', onTap: () {},
                          ),
                        ].map((story) => Padding(
                          padding: const EdgeInsets.only(right: DesignTokens.m),
                          child: StoryActivityItem(story: story),
                        )).toList(),
                      ),
                    ),

                    // Bottom padding
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: PollinatorBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemSelected: (index) {
          if (_selectedIndex == index) return;

          setState(() {
            _selectedIndex = index;
          });

          switch (index) {
            case 0: // Home
              break;
            case 1: // Identify
              Navigator.pushNamed(context, '/identify').then((_) {
                setState(() => _selectedIndex = 0);
                _refreshData(); // Refresh data when returning from identify page
              });
              break;
            case 2: // Map
              Navigator.pushNamed(context, '/map').then((_) => setState(() => _selectedIndex = 0));
              break;
            case 3: // Garden
              Navigator.pushNamed(context, '/garden').then((_) => setState(() => _selectedIndex = 0));
              break;
          }
        },
      ),
    );
  }

  // Consistent section header builder with aligned action widget
  Widget _buildSectionHeader({
    required String title,
    required Widget actionWidget,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.m),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: DesignTokens.titleMedium.copyWith(
              color: Theme.of(context).colorScheme.onBackground,
              fontWeight: FontWeight.w600,
            ),
          ),
          actionWidget,
        ],
      ),
    );
  }

  // Helper for building section actions with consistent styling
  Widget _buildSectionAction({
    required String label,
    required VoidCallback onPressed,
    Widget? trailing,
    bool rotateTrailing = false,
  }) {
    final color = Theme.of(context).colorScheme.primary;

    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: Size.zero,
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.s,
          vertical: DesignTokens.xxs,
        ),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: DesignTokens.xxs),
            rotateTrailing
                ? AnimatedRotation(
                    turns: _isActivityExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: trailing,
                  )
                : trailing,
          ],
        ],
      ),
    );
  }

  // Activity Cards
  Widget _buildActivityCards() {
    // Show loader during initial load
    if (_loadingTargets || _loadingStats) {
      return const SizedBox(
        height: 170,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return SizedBox(
      height: 180, // Increased from 170 to accommodate the larger cards
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: DesignTokens.m),
        children: [
          // Sightings Goal Card
          SizedBox(
            width: 130,
            child: ActivityStatCard(
              label: 'Sightings Goal',
              value: _sightingsCount,
              target: _sightingsTarget,
              icon: Icons.visibility_rounded,
              showProgress: true,
              onTap: () => _showSetTargetDialog(TargetService.SIGHTINGS_TARGET, _sightingsTarget),
              heroTag: 'stats-sightings',
            ),
          ),
          const SizedBox(width: DesignTokens.m),

          // Species Goal Card
          SizedBox(
            width: 130,
            child: ActivityStatCard(
              label: 'Species Goal',
              value: _speciesCount,
              target: _speciesTarget,
              icon: Icons.auto_awesome_rounded,
              showProgress: true,
              onTap: () => _showSetTargetDialog(TargetService.SPECIES_TARGET, _speciesTarget),
              heroTag: 'stats-species',
            ),
          ),
          const SizedBox(width: DesignTokens.m),

          // Gardens Card
          SizedBox(
            width: 130,
            child: ActivityStatCard(
              label: 'Gardens',
              value: _gardensCount,
              icon: Icons.local_florist_rounded,
              showProgress: false,
              onTap: () {
                Navigator.pushNamed(context, '/garden');
              },
              heroTag: 'stats-gardens',
            ),
          ),
          const SizedBox(width: DesignTokens.m),
          
          // Add Target Card
          SizedBox(
            width: 130,
            child: ActivityStatCard.addTarget(
              label: 'Add Target',
              onTap: () {
                // Show dialog to select target type
                showDialog(
                  context: context,
                  builder: (context) => SimpleDialog(
                    title: const Text('Add New Target'),
                    children: [
                      ListTile(
                        leading: const Icon(Icons.local_florist),
                        title: const Text('Garden Target'),
                        onTap: () {
                          Navigator.pop(context);
                          _showSetTargetDialog(TargetService.GARDENS_TARGET, _gardensTarget);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.visibility),
                        title: const Text('Sightings Target'),
                        onTap: () {
                          Navigator.pop(context);
                          _showSetTargetDialog(TargetService.SIGHTINGS_TARGET, _sightingsTarget);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.auto_awesome),
                        title: const Text('Species Target'),
                        onTap: () {
                          Navigator.pop(context);
                          _showSetTargetDialog(TargetService.SPECIES_TARGET, _speciesTarget);
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}