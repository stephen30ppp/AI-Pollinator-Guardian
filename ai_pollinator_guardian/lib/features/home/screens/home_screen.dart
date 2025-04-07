import 'package:flutter/material.dart';
import '../widgets/feature_card.dart';
import '../widgets/recent_activity_card.dart';
import 'package:ai_pollinator_guardian/widgets/bottom_navigation_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Mapping: 0: Home, 1: Identify, 2: Map (via FAB), 3: Garden, 4: Chat.
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AI Pollinator Guardian',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF4CAF50),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: () {
              // Info button action
            },
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Handle map navigation
          Navigator.pushNamed(context, '/map');
        },
        backgroundColor: const Color(0xFF4CAF50),
        elevation: 2,
        child: const Text('🗺️', style: TextStyle(fontSize: 24)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: PollinatorBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });

          // Handle navigation based on index
          if (index == 4) {
            // Chat
            Navigator.pushNamed(context, '/chat');
          } else if (index == 1) {
            // Identify
            Navigator.pushNamed(context, '/identify');
          } else if (index == 3) {
            // Garden
            Navigator.pushNamed(context, '/garden');
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
          imagePath: 'assets/images/garden_scanner.jpg',
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