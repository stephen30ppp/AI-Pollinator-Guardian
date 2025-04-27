import 'package:ai_pollinator_guardian/features/authentication/providers/auth_provider.dart';
import 'package:ai_pollinator_guardian/features/home/widgets/avatar_glow.dart';
import 'package:ai_pollinator_guardian/widgets/map_fab.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/feature_card.dart';
import 'package:ai_pollinator_guardian/widgets/bottom_navigation_bar.dart';
import 'package:ai_pollinator_guardian/constants/app_colors.dart';

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

  // For facts carousel
  int _currentFactIndex = 0;
  final List<Map<String, String>> _facts = [
    {
      'text':
          'Bees can recognize human faces, and they have excellent memory skills.',
      'source': 'Science Daily',
    },
    {
      'text':
          'A single bee colony can pollinate up to 300 million flowers in a single day.',
      'source': 'National Geographic',
    },
    {
      'text': 'Monarch butterflies migrate over 3,000 miles each year.',
      'source': 'WWF',
    },
    {
      'text': 'Some flowers use electric fields to communicate with bees.',
      'source': 'PNAS Journal',
    },
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_handleScroll);

    // Auto-rotate facts every 8 seconds
    Future.delayed(const Duration(seconds: 8), _rotateFact);
  }

  void _rotateFact() {
    if (!mounted) return;

    setState(() {
      _currentFactIndex = (_currentFactIndex + 1) % _facts.length;
    });

    Future.delayed(const Duration(seconds: 8), _rotateFact);
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
            automaticallyImplyLeading: false,
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcomeBanner(),
                  const SizedBox(height: 20),
                  _buildFeatureCards(),
                  const SizedBox(height: 24),
                  _buildRecentActivitySection(),
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

  Widget _buildWelcomeBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // align to top
        children: [
          // 🐝 icon
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF4CAF50),
            ),
            child: const Center(
              child: Text('🐝', style: TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 16),

          // Content area with fact carousel
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Good Day, Nature Guardian!",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  child: Text(
                    _facts[_currentFactIndex]['text']!,
                    key: ValueKey(_currentFactIndex),
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Source: ${_facts[_currentFactIndex]['source']}",
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),
          // align top
          Align(
            alignment: Alignment.topCenter,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/map'),
              icon: const Icon(Icons.add_circle_outline, size: 16),
              label: const Text(
                "Log a sighting",
                style: TextStyle(fontSize: 12),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCards() {
    // Create a PageView to make cards swipeable
    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PageView(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FeatureCard(
                  title: 'Identify Pollinators',
                  description:
                      'Snap a photo to reveal the secret lives of bees & butterflies.',
                  imagePath: 'assets/images/identify_pollinators.jpg',
                  onTap: () {
                    Navigator.pushNamed(context, '/identify');
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: FeatureCard(
                  title: 'Garden Scanner',
                  description:
                      'Analyze your garden and get custom pollinator tips.',
                  imagePath: 'assets/images/garden_scanner.jpg',
                  onTap: () {
                    Navigator.pushNamed(context, '/garden');
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Add page indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.withOpacity(0.3),
              ),
            ),
          ],
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

        // Transform to story-style circles
        SizedBox(
          height: 110,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildStoryItem(
                'Bumblebee',
                'Today',
                'assets/images/bumblebee.jpg',
              ),
              _buildStoryItem(
                'Monarch',
                'Yesterday',
                'assets/images/monarch.jpg',
              ),
              _buildStoryItem(
                'Garden',
                '2 days ago',
                'assets/images/garden.jpg',
              ),
              _buildStoryItem(
                'Honeybee',
                '3 days ago',
                'assets/images/honeybee.jpg',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStoryItem(String title, String date, String imagePath) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          // Circular image with gradient border
          Container(
            width: 72,
            height: 72,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.primaryColor, AppColors.accentColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(34),
                child: Image.asset(
                  imagePath,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Title
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          ),
          // Date
          Text(date, style: TextStyle(color: Colors.grey[600], fontSize: 10)),
        ],
      ),
    );
  }
}
