import 'package:flutter/foundation.dart';

// 全局当前选中的底部导航栏索引
// 0: Home, 1: Identify, 2: Map, 3: Garden, 4: Chat
final currentTab = ValueNotifier<int>(0);