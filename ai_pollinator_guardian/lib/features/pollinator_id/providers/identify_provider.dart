import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/identify_result.dart';
import '../services/identify_api.dart'; // 假设有这个服务用于API调用

class IdentifyProvider with ChangeNotifier {
  IdentifyResult? _result;
  String? _error;
  File? _selectedImage; // 添加图像存储变量

  bool get analysisReady => _result != null && _error == null;
  IdentifyResult? get result => _result;
  String? get error => _error;
  File? get selectedImage => _selectedImage; // 添加图像访问器

  Future<void> identify(XFile img) async {
    try {
      final apiRes = await identifyApi(img);
      final parsed = IdentifyResult.fromMap(apiRes);
      if (parsed == null) {
        _error = 'Unable to parse';
      } else {
        _result = parsed;
        _error  = null;
      }
    } catch (e) {
      _error = e.toString();
      _result = null;
    }
    notifyListeners();                      // 只管广播，导航交给 UI
  }

  void reset() {
    _result = null;
    _error  = null;
    _selectedImage = null; // 清除图像
    notifyListeners();
  }
  
  // 添加 setResult 方法
  void setResult(Map<String, dynamic>? identificationResult, {required File? image}) {
    if (identificationResult != null) {
      _result = IdentifyResult.fromMap(identificationResult);
      _error = null;
    } else {
      _result = null;
    }
    _selectedImage = image;
    notifyListeners();
  }
  
  // 添加 resetResult 方法作为 reset 的别名
  void resetResult() {
    reset();
  }
}