import 'dart:io';
import 'package:flutter/material.dart';

class IdentifyProvider with ChangeNotifier {
  Map<String, dynamic>? _result;
  File? _selectedImage;
  bool _analysisReady = false; // 添加分析就绪状态标志

  Map<String, dynamic>? get result => _result;
  File? get selectedImage => _selectedImage;
  bool get hasResult => _result != null;
  bool get analysisReady => _analysisReady; // 暴露分析就绪状态

  void setResult(Map<String, dynamic>? result, {File? image}) {
    _result = result;
    if (image != null) {
      _selectedImage = image;
    }
    _analysisReady = result != null; // 有结果时表示分析就绪
    notifyListeners();
  }

  void resetResult() {
    _result = null;
    _selectedImage = null;
    _analysisReady = false; // 重置分析就绪状态
    notifyListeners();
  }
}