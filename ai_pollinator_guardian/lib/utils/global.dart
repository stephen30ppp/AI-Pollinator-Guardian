import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 0‑Home  1‑Identify  2‑Map  3‑Garden  4‑Chat
final currentTab = ValueNotifier<int>(0);

// 各个标签页的导航键
final navKeys = {
  0: GlobalKey<NavigatorState>(), // Home
  1: GlobalKey<NavigatorState>(), // Identify
  2: GlobalKey<NavigatorState>(), // Map
  3: GlobalKey<NavigatorState>(), // Garden
  4: GlobalKey<NavigatorState>(), // Chat
};