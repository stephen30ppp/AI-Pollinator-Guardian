/// Firebase Cloud Storage utilities + local picker convenience.
/// Docs: https://firebase.google.com/docs/storage/flutter/start
///
library;

import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:image/image.dart' as img;

/// Custom exception for storage operations
class StorageException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  StorageException(this.message, {this.code, this.originalError});

  @override
  String toString() =>
      'StorageException: $message${code != null ? ' [Code: $code]' : ''}';
}

class StorageService {
  // ── Singleton
  StorageService._internal();
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;

  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  // region --- FOLDER mgmt ---
  /// Firebase Storage uses prefixes – create by uploading stub.
  /// Creates a folder in Firebase Storage if it doesn't exist.
  ///
  /// [folder] the path where the folder should be created
  Future<void> createFolderIfAbsent(String folder) async {
    debugPrint('🗂️ Creating folder if absent: $folder');

    if (folder.isEmpty) {
      throw StorageException('Invalid folder path: Empty path provided');
    }

    final ref = _storage.ref(folder).child('_._'); // reserved blob
    try {
      await ref.putData(Uint8List(0));
      debugPrint('✅ Folder created/verified: $folder');
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') {
        debugPrint('⚠️ Object not found, but this is expected: $folder');
      } else {
        debugPrint('❌ Error creating folder: ${e.code} - ${e.message}');
        throw StorageException(
          'Failed to create folder: ${e.message}',
          code: e.code,
          originalError: e,
        );
      }
    } catch (e) {
      debugPrint('❌ Unexpected error creating folder: $e');
      throw StorageException(
        'Unexpected error creating folder',
        originalError: e,
      );
    }
  }
  // endregion

  // region --- UPLOAD ---
  /// Uploads a file to Firebase Storage
  ///
  /// [file] The file to upload
  /// [folder] The folder path where the file should be stored
  /// [fileName] Optional custom filename, defaults to original filename
  /// [metadata] Optional metadata for the file
  ///
  /// Returns the download URL for the uploaded file
  Future<String> uploadFile({
    required File file,
    required String folder,
    String? fileName,
    SettableMetadata? metadata,
  }) async {
    if (!file.existsSync()) {
      debugPrint('❌ File does not exist: ${file.path}');
      throw StorageException('File does not exist: ${file.path}');
    }

    final name = fileName ?? p.basename(file.path);
    debugPrint('📤 Uploading file: $name to folder: $folder');

    try {
      // Ensure folder exists
      await createFolderIfAbsent(folder);

      final ref = _storage.ref(folder).child(name);

      // Start upload
      final UploadTask task = ref.putFile(file, metadata);

      // Listen to task progress
      task.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        debugPrint(
          '📊 Upload progress: ${(progress * 100).toStringAsFixed(1)}%',
        );
      });

      // Wait for completion
      final snapshot = await task;
      debugPrint(
        '✅ File uploaded successfully: $name (${snapshot.bytesTransferred} bytes)',
      );

      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      debugPrint('🔗 Download URL: $downloadUrl');

      return downloadUrl;
    } on FirebaseException catch (e) {
      debugPrint('❌ Firebase error uploading file: ${e.code} - ${e.message}');
      throw StorageException(
        'Failed to upload file: ${e.message}',
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      debugPrint('❌ Unexpected error uploading file: $e');
      throw StorageException(
        'Unexpected error uploading file',
        originalError: e,
      );
    }
  }

  /// Uploads raw bytes to Firebase Storage
  ///
  /// [bytes] The byte data to upload
  /// [folder] The folder path where the file should be stored
  /// [fileName] The filename for the uploaded data
  /// [metadata] Optional metadata for the file
  ///
  /// Returns the download URL for the uploaded file
  Future<String> uploadBytes({
    required Uint8List bytes,
    required String folder,
    required String fileName,
    SettableMetadata? metadata,
  }) async {
    if (bytes.isEmpty) {
      debugPrint('❌ Cannot upload empty bytes');
      throw StorageException('Cannot upload empty bytes');
    }

    debugPrint(
      '📤 Uploading bytes: $fileName (${bytes.length} bytes) to folder: $folder',
    );

    try {
      // Ensure folder exists
      await createFolderIfAbsent(folder);

      final ref = _storage.ref(folder).child(fileName);

      // Start upload
      final UploadTask task = ref.putData(bytes, metadata);

      // Listen to task progress
      task.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        debugPrint(
          '📊 Upload progress: ${(progress * 100).toStringAsFixed(1)}%',
        );
      });

      // Wait for completion
      final snapshot = await task;
      debugPrint(
        '✅ Bytes uploaded successfully: $fileName (${snapshot.bytesTransferred} bytes)',
      );

      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      debugPrint('🔗 Download URL: $downloadUrl');

      return downloadUrl;
    } on FirebaseException catch (e) {
      debugPrint('❌ Firebase error uploading bytes: ${e.code} - ${e.message}');
      throw StorageException(
        'Failed to upload bytes: ${e.message}',
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      debugPrint('❌ Unexpected error uploading bytes: $e');
      throw StorageException(
        'Unexpected error uploading bytes',
        originalError: e,
      );
    }
  }

  /// Batch upload multiple files with progress tracking
  ///
  /// [files] List of files to upload
  /// [folder] Target folder for uploads
  /// [onProgress] Optional callback for tracking overall progress (0-1)
  ///
  /// Returns a list of download URLs for the uploaded files
  Future<List<String>> uploadFiles({
    required List<File> files,
    required String folder,
    ValueChanged<double>? onProgress, // 0-1 per file
  }) async {
    if (files.isEmpty) {
      debugPrint('⚠️ No files to upload');
      return [];
    }

    debugPrint('📤 Batch uploading ${files.length} files to folder: $folder');

    final urls = <String>[];
    int failedCount = 0;

    for (final (idx, file) in files.indexed) {
      try {
        debugPrint(
          '📄 Uploading file ${idx + 1}/${files.length}: ${file.path}',
        );
        final url = await uploadFile(file: file, folder: folder);
        urls.add(url);

        // Update progress
        final progress = (idx + 1) / files.length;
        onProgress?.call(progress);
        debugPrint(
          '📊 Batch progress: ${(progress * 100).toStringAsFixed(1)}%',
        );
      } catch (e) {
        debugPrint('❌ Error uploading file ${idx + 1}: $e');
        failedCount++;
        // Continue with next file despite errors
      }
    }

    if (failedCount > 0) {
      debugPrint(
        '⚠️ Completed batch upload with $failedCount failed files. Successfully uploaded: ${urls.length}/${files.length}',
      );
    } else {
      debugPrint('✅ Successfully uploaded all ${files.length} files');
    }

    return urls;
  }

  /// Retries an upload operation with exponential backoff
  ///
  /// [operation] The upload function to retry
  /// [maxAttempts] Maximum number of retry attempts
  ///
  /// Returns the result of the successful operation
  Future<T> _retryUpload<T>(
    Future<T> Function() operation, {
    int maxAttempts = 3,
    Duration initialDelay = const Duration(seconds: 1),
  }) async {
    int attempts = 0;
    Duration delay = initialDelay;

    while (true) {
      attempts++;
      try {
        return await operation();
      } on FirebaseException catch (e) {
        // Only retry on network/server errors
        final bool isRetryable =
            e.code == 'network-request-failed' ||
            e.code == 'unavailable' ||
            e.code == 'deadline-exceeded';

        if (!isRetryable || attempts >= maxAttempts) {
          debugPrint('❌ Upload failed after $attempts attempts: ${e.code}');
          rethrow;
        }

        debugPrint(
          '⚠️ Retryable error (${e.code}), attempt $attempts/$maxAttempts. Retrying in ${delay.inMilliseconds}ms...',
        );
        await Future.delayed(delay);

        // Exponential backoff
        delay *= 2;
      }
    }
  }
  // endregion

  // region --- LIST / METADATA ---
  /// Lists all files in a folder
  ///
  /// [folder] The folder path to list files from
  ///
  /// Returns a list of References to the files
  Future<List<Reference>> listAllFiles(String folder) async {
    debugPrint('📋 Listing all files in folder: $folder');

    try {
      final result = await _storage.ref(folder).listAll();
      debugPrint(
        '✅ Found ${result.items.length} files and ${result.prefixes.length} subfolders in $folder',
      );
      return result.items;
    } on FirebaseException catch (e) {
      debugPrint('❌ Firebase error listing files: ${e.code} - ${e.message}');
      throw StorageException(
        'Failed to list files: ${e.message}',
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      debugPrint('❌ Unexpected error listing files: $e');
      throw StorageException(
        'Unexpected error listing files',
        originalError: e,
      );
    }
  }

  /// Lists files in a folder with pagination
  ///
  /// [folder] The folder path to list files from
  /// [maxResults] Maximum number of results per page
  /// [nextPageToken] Token for the next page
  ///
  /// Returns a paginated result of files
  Future<ListResult> listFilesPaged(
    String folder, {
    int maxResults = 20,
    String? nextPageToken,
  }) async {
    debugPrint(
      '📋 Listing files in folder (paged): $folder (max: $maxResults, token: ${nextPageToken?.substring(0, min(10, nextPageToken.length)) ?? "null"})',
    );

    try {
      final result = await _storage
          .ref(folder)
          .list(ListOptions(maxResults: maxResults, pageToken: nextPageToken));

      debugPrint(
        '✅ Found ${result.items.length} files. Has more: ${result.nextPageToken != null}',
      );
      return result;
    } on FirebaseException catch (e) {
      debugPrint(
        '❌ Firebase error listing files (paged): ${e.code} - ${e.message}',
      );
      throw StorageException(
        'Failed to list files: ${e.message}',
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      debugPrint('❌ Unexpected error listing files (paged): $e');
      throw StorageException(
        'Unexpected error listing files',
        originalError: e,
      );
    }
  }

  /// Gets the download URL for a file reference
  ///
  /// [ref] Reference to the file
  ///
  /// Returns the download URL as a string
  Future<String> getDownloadUrl(Reference ref) async {
    debugPrint('🔗 Getting download URL for: ${ref.fullPath}');

    try {
      final url = await ref.getDownloadURL();
      debugPrint('✅ Got download URL: $url');
      return url;
    } on FirebaseException catch (e) {
      debugPrint(
        '❌ Firebase error getting download URL: ${e.code} - ${e.message}',
      );
      throw StorageException(
        'Failed to get download URL: ${e.message}',
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      debugPrint('❌ Unexpected error getting download URL: $e');
      throw StorageException(
        'Unexpected error getting download URL',
        originalError: e,
      );
    }
  }

  /// Gets metadata for a file reference
  ///
  /// [ref] Reference to the file
  ///
  /// Returns the full metadata for the file
  Future<FullMetadata> getMetadata(Reference ref) async {
    debugPrint('📝 Getting metadata for: ${ref.fullPath}');

    try {
      final metadata = await ref.getMetadata();
      debugPrint(
        '✅ Got metadata. Content type: ${metadata.contentType}, size: ${metadata.size} bytes',
      );
      return metadata;
    } on FirebaseException catch (e) {
      debugPrint('❌ Firebase error getting metadata: ${e.code} - ${e.message}');
      throw StorageException(
        'Failed to get metadata: ${e.message}',
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      debugPrint('❌ Unexpected error getting metadata: $e');
      throw StorageException(
        'Unexpected error getting metadata',
        originalError: e,
      );
    }
  }
  // endregion

  // region --- DELETE ---
  /// Deletes a file or folder
  ///
  /// [ref] Reference to the file or folder to delete
  Future<void> deleteFileOrFolder(Reference ref) async {
    debugPrint('🗑️ Deleting file or folder: ${ref.fullPath}');

    try {
      if (ref.fullPath.endsWith('/')) {
        await deleteFolderRecursive(ref.fullPath);
      } else {
        await ref.delete();
        debugPrint('✅ File deleted: ${ref.fullPath}');
      }
    } on FirebaseException catch (e) {
      // Handle case where the file might already be deleted
      if (e.code == 'object-not-found') {
        debugPrint(
          '⚠️ File or folder not found (already deleted): ${ref.fullPath}',
        );
      } else {
        debugPrint(
          '❌ Firebase error deleting file/folder: ${e.code} - ${e.message}',
        );
        throw StorageException(
          'Failed to delete file/folder: ${e.message}',
          code: e.code,
          originalError: e,
        );
      }
    } catch (e) {
      debugPrint('❌ Unexpected error deleting file/folder: $e');
      throw StorageException(
        'Unexpected error deleting file/folder',
        originalError: e,
      );
    }
  }

  /// Recursively deletes all files in a folder
  ///
  /// [folder] Path to the folder to delete
  Future<void> deleteFolderRecursive(String folder) async {
    debugPrint('🗑️ Recursively deleting folder: $folder');

    try {
      final items = await listAllFiles(folder);

      if (items.isEmpty) {
        debugPrint('ℹ️ No files found to delete in folder: $folder');
        return;
      }

      debugPrint('🗑️ Deleting ${items.length} files in folder: $folder');

      int deletedCount = 0;
      for (final item in items) {
        try {
          await item.delete();
          deletedCount++;
          debugPrint(
            '✅ Deleted file ${deletedCount}/${items.length}: ${item.fullPath}',
          );
        } catch (e) {
          debugPrint('⚠️ Error deleting file: ${item.fullPath} - $e');
          // Continue deleting other files despite errors
        }
      }

      debugPrint(
        '✅ Deleted $deletedCount/${items.length} files in folder: $folder',
      );
    } on FirebaseException catch (e) {
      debugPrint(
        '❌ Firebase error deleting folder recursively: ${e.code} - ${e.message}',
      );
      throw StorageException(
        'Failed to delete folder: ${e.message}',
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      debugPrint('❌ Unexpected error deleting folder recursively: $e');
      throw StorageException(
        'Unexpected error deleting folder',
        originalError: e,
      );
    }
  }
  // endregion

  // region --- LOCAL PICKER (enhanced) ---
  /// Takes a photo using the device camera
  ///
  /// Returns the captured image as a File, or null if canceled/failed
  Future<File?> takePhoto({int imageQuality = 80}) async {
    debugPrint('📸 Opening camera to take photo');
    return _pick(ImageSource.camera, imageQuality: imageQuality);
  }

  /// Picks an image from the device gallery
  ///
  /// Returns the selected image as a File, or null if canceled/failed
  Future<File?> pickImage({int imageQuality = 80}) async {
    debugPrint('🖼️ Opening gallery to pick image');
    return _pick(ImageSource.gallery, imageQuality: imageQuality);
  }

  /// Internal method to pick an image from a source
  Future<File?> _pick(ImageSource source, {int imageQuality = 80}) async {
    try {
      final XFile? xFile = await _picker.pickImage(
        source: source,
        imageQuality: imageQuality,
      );

      if (xFile == null) {
        debugPrint('ℹ️ Image picking canceled by user');
        return null;
      }

      debugPrint('✅ Image picked: ${xFile.path} (source: ${source.name})');
      return File(xFile.path);
    } catch (e) {
      debugPrint('❌ Error picking image: $e');
      return null;
    }
  }

  /// Converts a File to a Uint8List of bytes
  // Future<Uint8List?> fileToBytes(File file) async {
  //   try {
  //     debugPrint('📊 Converting file to bytes: ${file.path}');
  //     final bytes = await file.readAsBytes();
  //     debugPrint('✅ File converted to bytes: ${bytes.length} bytes');
  //     return bytes;
  //   } catch (e) {
  //     debugPrint('❌ Error converting file to bytes: $e');
  //     return null;
  //   }
  // }
  // endregion

  Future<Uint8List?> fileToBytes(File file, {required String format}) async {
    try {
      final bytes = await file.readAsBytes();
      // Decode the image and re-encode as JPEG
      final decodedImage = img.decodeImage(bytes);
      if (decodedImage != null) {
        return Uint8List.fromList(img.encodeJpg(decodedImage));
      }
      return bytes; // Return original bytes if decoding fails
    } catch (e) {
      debugPrint('Error converting file to bytes: $e');
      return null;
    }
  }
}

// Helper function for min value
int min(int a, int b) => a < b ? a : b;
