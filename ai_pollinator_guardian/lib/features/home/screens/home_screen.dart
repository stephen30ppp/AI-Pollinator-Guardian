import 'package:flutter/material.dart';
import '../widgets/feature_card.dart';
import '../widgets/recent_activity_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Pollinator Guardian'),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              // Info button action
            },
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeBanner(),
          const SizedBox(height: 20),
          _buildFeatureCards(),
          const SizedBox(height: 24),
          _buildRecentActivitySection(),
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
              child: Text(
                '🐝',
                style: TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome, Nature Guardian!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Help protect our pollinators today',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
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
          description: 'Take a photo to identify bee and butterfly species',
          imagePath: 'assets/images/identify_pollinators.jpg',
          onTap: () {
            // Navigate to identification screen
          },
        ),
        const SizedBox(height: 20),
        FeatureCard(
          title: 'Garden Scanner',
          description: 'Analyze your garden and get recommendations',
          imagePath: 'assets/images/garden_scanner.jpg',
          onTap: () {
            // Navigate to garden scanner screen
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
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            GestureDetector(
              onTap: () {
                // View all action
              },
              child: const Text(
                'View all',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF4CAF50),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              RecentActivityCard(
                title: 'Bumblebee',
                date: 'Today',
                imagePath: 'assets/images/bumblebee.jpg',
                onTap: () {},
              ),
              RecentActivityCard(
                title: 'Monarch',
                date: 'Yesterday',
                imagePath: 'assets/images/monarch.jpg',
                onTap: () {},
              ),
              RecentActivityCard(
                title: 'My Garden',
                date: '2 days ago',
                imagePath: 'assets/images/garden.jpg',
                onTap: () {},
              ),
              RecentActivityCard(
                title: 'Honeybee',
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

  Widget _buildBottomNav() {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(icon: '🏠', label: 'Home', index: 0),
          _buildNavItem(icon: '📷', label: 'Identify', index: 1),
          _buildNavItem(icon: '🗺️', label: 'Map', index: 2),
          _buildNavItem(icon: '💬', label: 'Chat', index: 3),
        ],
      ),
    );
  }

  Widget _buildNavItem({required String icon, required String label, required int index}) {
    final bool isActive = _selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
          // Handle navigation here
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              icon,
              style: TextStyle(
                fontSize: 24,
                color: isActive ? const Color(0xFF4CAF50) : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isActive ? const Color(0xFF4CAF50) : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}