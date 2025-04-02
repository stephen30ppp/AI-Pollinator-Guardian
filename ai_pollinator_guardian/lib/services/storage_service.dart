import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final ImagePicker _picker = ImagePicker();
  static const Uuid _uuid = Uuid();

  // Take a photo with the camera
  Future<File?> takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      
      if (photo != null) {
        return File(photo.path);
      }
      return null;
    } catch (e) {
      print('Error taking photo: $e');
      return null;
    }
  }

  // Pick an image from the gallery
  Future<File?> pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      print('Error picking image: $e');
      return null;
    }
  }
  
  // Convert a file to bytes
  Future<Uint8List?> fileToBytes(File file) async {
    try {
      return await file.readAsBytes();
    } catch (e) {
      print('Error converting file to bytes: $e');
      return null;
    }
  }
  
  // Save image to temporary directory and return the file
  Future<File?> saveBytesToFile(Uint8List bytes, {String? fileName}) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final name = fileName ?? '${_uuid.v4()}.jpg';
      final file = File('${tempDir.path}/$name');
      await file.writeAsBytes(bytes);
      return file;
    } catch (e) {
      print('Error saving bytes to file: $e');
      return null;
    }
  }
  
  // Save image to local app directory
  Future<String?> saveImageLocally(Uint8List bytes, String folderName) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final dirPath = '${appDir.path}/$folderName';
      
      // Create directory if it doesn't exist
      final dir = Directory(dirPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      
      final fileName = '${_uuid.v4()}.jpg';
      final filePath = '$dirPath/$fileName';
      final file = File(filePath);
      
      await file.writeAsBytes(bytes);
      return filePath;
    } catch (e) {
      print('Error saving image locally: $e');
      return null;
    }
  }
  
  // Load image from local app directory
  Future<Uint8List?> loadLocalImage(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        return await file.readAsBytes();
      }
      return null;
    } catch (e) {
      print('Error loading local image: $e');
      return null;
    }
  }

  // Generate a unique file name with extension
  String generateUniqueFileName(String extension) {
    return '${_uuid.v4()}.$extension';
  }
}