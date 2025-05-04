import 'package:flutter/material.dart';
import 'package:ai_pollinator_guardian/utils/global.dart';
import 'package:ai_pollinator_guardian/features/home/screens/home_screen.dart';
import 'package:ai_pollinator_guardian/features/pollinator_id/screens/pollinator_id_screen.dart';
import 'package:ai_pollinator_guardian/features/community_map/screens/community_map_screen.dart';
import 'package:ai_pollinator_guardian/features/garden_scanner/screens/garden_scanner_screen.dart';
import 'package:ai_pollinator_guardian/features/chat_assistant/screens/chat_screen.dart';
import 'package:ai_pollinator_guardian/widgets/bottom_navigation_bar.dart';

class MainContainerScreen extends StatefulWidget {
  const MainContainerScreen({super.key});

  @override
  State<MainContainerScreen> createState() => _MainContainerScreenState();
}

class _MainContainerScreenState extends State<MainContainerScreen> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    // 监听全局选中的索引变化
    currentTab.addListener(() {
      setState(() {
        _index = currentTab.value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final nav = navKeys[_index]!.currentState!;
        if (nav.canPop()) {
          nav.pop();
          return false;            // 已消费
        }
        return true;               // 退出 app
      },
      child: Scaffold(
        body: IndexedStack(
          index: _index,
          children: [
            _buildTabNavigator(0, const HomeScreen()),
            _buildTabNavigator(1, const PollinatorIdScreen()),
            _buildTabNavigator(2, const CommunityMapScreen()),
            _buildTabNavigator(3, const GardenScannerScreen()),
            _buildTabNavigator(4, const ChatScreen()),
          ],
        ),
        bottomNavigationBar: PollinatorBottomNavBar(
          selectedIndex: _index,
          onItemSelected: (index) {
            setState(() {
              _index = index;
            });
            currentTab.value = index; // 更新全局选中索引
          },
        ),
      ),
    );
  }

  Widget _buildTabNavigator(int tabIdx, Widget rootPage) {
    return Navigator(
      key: navKeys[tabIdx],
      onGenerateRoute: (settings) => MaterialPageRoute(
        builder: (_) => rootPage,
      ),
    );
  }
}