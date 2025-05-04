import 'package:flutter/material.dart';
import 'package:ai_pollinator_guardian/utils/global.dart';
import 'package:ai_pollinator_guardian/features/home/screens/home_screen.dart';
import 'package:ai_pollinator_guardian/features/pollinator_id/screens/pollinator_id_screen.dart';
import 'package:ai_pollinator_guardian/features/community_map/screens/community_map_screen.dart';
import 'package:ai_pollinator_guardian/features/garden_scanner/screens/garden_scanner_screen.dart';
import 'package:ai_pollinator_guardian/features/chat_assistant/screens/chat_screen.dart';
import 'package:ai_pollinator_guardian/widgets/bottom_navigation_bar.dart';

class RootScaffold extends StatefulWidget {
  const RootScaffold({super.key});
  
  /// 公开某个 key 供子页面 push
  static GlobalKey<NavigatorState> nav(int idx, BuildContext context) =>
      (context.findAncestorStateOfType<_RootScaffoldState>()?._navKeys[idx])!;
      
  @override
  State<RootScaffold> createState() => _RootScaffoldState();
}

class _RootScaffoldState extends State<RootScaffold> {
  int _idx = 0;                                         // 默认打开 Home
  final _navKeys = List.generate(5, (_) => GlobalKey<NavigatorState>());

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final nav = _navKeys[_idx].currentState!;
        if (nav.canPop()) {
          nav.pop();
          return false;           // 自己消费
        }
        return true;              // 退出 app
      },
      child: Scaffold(
        body: IndexedStack(
          index: _idx,
          children: [
            _tabNav(0, const HomeScreen()),
            _tabNav(1, const PollinatorIdScreen()),
            _tabNav(2, const CommunityMapScreen()),
            _tabNav(3, const GardenScannerScreen()),
            _tabNav(4, const ChatScreen()),
          ],
        ),
        bottomNavigationBar: PollinatorBottomNavBar(
          selectedIndex: _idx,
          onItemSelected: (i) {
            setState(() => _idx = i);
            currentTab.value = i;               // ← 关键
          },
        ),
      ),
    );
  }

  Widget _tabNav(int i, Widget root) => Navigator(
    key: _navKeys[i],
    onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => root),
  );
}
/// 常见错误:
/// 1. 把 Navigator 写在 IndexedStack 外面 ⇒ 仍然只有一个栈，会被 pop。
/// 2. 忘记给每个 Navigator 不同的 key ⇒ 状态混乱。