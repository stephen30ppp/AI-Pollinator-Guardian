import 'dart:io';
import 'package:flutter/material.dart';

class GardenScannerProvider with ChangeNotifier {
  Map<String, dynamic>? _report;
  List<File> _gardenImages = [];
  bool _analysisReady = false; // 添加分析就绪状态标志

  Map<String, dynamic>? get report => _report;
  List<File> get gardenImages => _gardenImages;
  bool get hasAnalysis => _report != null;
  bool get analysisReady => _analysisReady; // 暴露分析就绪状态

  void setAnalysis(Map<String, dynamic>? analysis, {List<File>? images}) {
    _report = analysis;
    if (images != null) {
      _gardenImages = images;
    }
    _analysisReady = analysis != null; // 有分析报告时表示分析就绪
    notifyListeners();
  }

  void addImage(File image) {
    _gardenImages.add(image);
    notifyListeners();
  }

  void removeImage(File image) {
    _gardenImages.remove(image);
    notifyListeners();
  }

  void resetAnalysis() {
    _report = null;
    _gardenImages.clear();
    _analysisReady = false; // 重置分析就绪状态
    notifyListeners();
  }
}