import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ai_pollinator_guardian/features/authentication/providers/auth_provider.dart';
import 'package:ai_pollinator_guardian/features/home/widgets/avatar_glow.dart';
import 'package:ai_pollinator_guardian/features/home/widgets/fact_carousel.dart';
import 'package:ai_pollinator_guardian/features/home/widgets/feature_card_carousel.dart';
import 'package:ai_pollinator_guardian/features/home/widgets/story_activity.dart';
import 'package:ai_pollinator_guardian/widgets/bottom_navigation_bar.dart';
import 'package:ai_pollinator_guardian/constants/app_colors.dart';
import 'package:ai_pollinator_guardian/constants/design_tokens.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Mapping: 0: Home, 1: Identify, 2: Map (via FAB), 3: Garden, 4: Chat
  int _selectedIndex = 0;
  late ScrollController _scrollController;
  double _fabOffset = 0;
  final double _maxFabOffset = 100;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    final offset = _scrollController.offset;
    final maxScroll = _scrollController.position.maxScrollExtent;

    // Update FAB position based on scroll
    setState(() {
      _fabOffset = (offset / (maxScroll / 2)).clamp(0, 1) * _maxFabOffset;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Sliver App Bar with gradient
          SliverAppBar(
            automaticallyImplyLeading: false, // Disable back button on home
            pinned: true,
            toolbarHeight: kToolbarHeight, // 56px
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
              // Profile icon in app bar with glow effect
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
              padding: const EdgeInsets.all(DesignTokens.m),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Banner with Facts Carousel
                  FactCardCarousel(
                    facts: PollinatorFact.sampleFacts,
                    onActionTap: () {
                      Navigator.pushNamed(context, '/map');
                    },
                    actionLabel: 'Log a sighting',
                    greeting: 'Good Day, Nature Guardian!',
                  ),
                  const SizedBox(height: DesignTokens.l),
                  
                  // Feature Cards Carousel
                  FeatureCardCarousel(
                    items: [
                      FeatureCardItem(
                        title: 'Identify Pollinators',
                        description: 'Snap a photo to reveal the secret lives of bees & butterflies.',
                        imagePath: 'assets/images/identify_pollinators.jpg',
                        onTap: () {
                          Navigator.pushNamed(context, '/identify');
                        },
                      ),
                      FeatureCardItem(
                        title: 'Garden Scanner',
                        description: 'Analyze your garden and get custom pollinator tips.',
                        imagePath: 'assets/images/garden_scanner.jpg',
                        onTap: () {
                          Navigator.pushNamed(context, '/garden');
                        },
                      ),
                      FeatureCardItem(
                        title: 'Community Map',
                        description: 'Explore pollinator sightings in your area.',
                        imagePath: 'assets/images/map.jpg',
                        onTap: () {
                          Navigator.pushNamed(context, '/map');
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: DesignTokens.xl),
                  
                  // Recent Activity Section
                  StoryActivity(
                    title: 'Recent Activity',
                    onViewAll: () {
                      // Handle view all action
                    },
                    stories: [
                      StoryItem(
                        title: 'Bumblebee',
                        date: 'Today',
                        imagePath: 'assets/images/bumblebee.jpg',
                        onTap: () {
                          // Handle story tap
                        },
                      ),
                      StoryItem(
                        title: 'Monarch',
                        date: 'Yesterday',
                        imagePath: 'assets/images/monarch.jpg',
                        onTap: () {
                          // Handle story tap
                        },
                      ),
                      StoryItem(
                        title: 'Garden',
                        date: '2 days ago',
                        imagePath: 'assets/images/garden.jpg',
                        onTap: () {
                          // Handle story tap
                        },
                      ),
                      StoryItem(
                        title: 'Honeybee',
                        date: '3 days ago',
                        imagePath: 'assets/images/honeybee.jpg',
                        onTap: () {
                          // Handle story tap
                        },
                      ),
                    ],
                  ),
                  
                  // Add extra padding at bottom
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: PollinatorBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });

          // Handle navigation based on index
          if (index == 0) {
            // Home - already here, do nothing
          } else if (index == 1) {
            // Identify
            Navigator.pushNamed(context, '/identify');
          } else if (index == 2) {
            Navigator.pushNamed(context, '/map');
          } else if (index == 3) {
            // Garden
            Navigator.pushNamed(context, '/garden');
          } else if (index == 4) {
            // Chat
            Navigator.pushNamed(context, '/chat');
          }
        },
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeBanner(),
          const SizedBox(height: 20),
          _buildFeatureCards(),
          const SizedBox(height: 24),
          _buildRecentActivitySection(),
          // Add extra padding at bottom to ensure content doesn't get cut off
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildWelcomeBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFF4CAF50),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('🐝', style: TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Good Day, Nature Guardian!",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                Text(
                  "Let's create a vibrant haven for our buzzing friends.",
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCards() {
    return Column(
      children: [
        FeatureCard(
          title: 'Identify Pollinators',
          description:
              'Snap a photo to reveal the secret lives of bees & butterflies.',
          imagePath: 'assets/images/identify_pollinators.jpg',
          onTap: () {
            Navigator.pushNamed(context, '/identify');
          },
        ),
        const SizedBox(height: 20),
        FeatureCard(
          title: 'Garden Scanner',
          description: 'Analyze your garden and get custom pollinator tips.',
          imagePath: 'assets/images/garden 3.jpg',
          onTap: () {
            Navigator.pushNamed(context, '/garden');
          },
        ),
      ],
    );
  }

  Widget _buildRecentActivitySection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            GestureDetector(
              onTap: () {
                // View all action
              },
              child: const Text(
                'View all',
                style: TextStyle(fontSize: 14, color: Color(0xFF4CAF50)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Fixed width to prevent overflowing 
        SizedBox(
          height: 160,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              RecentActivityCard(
                title: 'Bumblebee Buzz',
                date: 'Today',
                imagePath: 'assets/images/bumblebee.jpg',
                onTap: () {},
              ),
              RecentActivityCard(
                title: 'Monarch Magic',
                date: 'Yesterday',
                imagePath: 'assets/images/monarch.jpg',
                onTap: () {},
              ),
              RecentActivityCard(
                title: 'My Blooming Garden',
                date: '2 days ago',
                imagePath: 'assets/images/garden.jpg',
                onTap: () {},
              ),
              RecentActivityCard(
                title: 'Honeybee Huddle',
                date: '3 days ago',
                imagePath: 'assets/images/honeybee.jpg',
                onTap: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }
}