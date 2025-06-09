import 'dart:io';
import 'package:file_picker/file_picker.dart' as picker;
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';

/// Service wrapper to handle file picking across platforms
class FileService {
  /// Pick a single file and return its path
  static Future<String?> pickSingleFile({
    List<String>? allowedExtensions,
    String? dialogTitle,
  }) async {
    // Use file_selector for desktop platforms
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final typeGroup = XTypeGroup(
        label: 'Files',
        extensions: allowedExtensions,
      );
      
      final file = await openFile(
        acceptedTypeGroups: [typeGroup],
      );
      
      return file?.path;
    } 
    // Use file_picker for mobile platforms
    else {
      final result = await picker.FilePicker.platform.pickFiles(
        type: allowedExtensions != null 
            ? picker.FileType.custom 
            : picker.FileType.any,
        allowedExtensions: allowedExtensions,
        dialogTitle: dialogTitle,
      );
      
      return result?.files.single.path;
    }
  }
  
  /// Pick multiple files and return their paths
  static Future<List<String>?> pickMultipleFiles({
    List<String>? allowedExtensions,
    String? dialogTitle,
  }) async {
    // Use file_selector for desktop platforms
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final typeGroup = XTypeGroup(
        label: 'Files',
        extensions: allowedExtensions,
      );
      
      final files = await openFiles(
        acceptedTypeGroups: [typeGroup],
      );
      
      return files.map((file) => file.path).toList();
    } 
    // Use file_picker for mobile platforms
    else {
      final result = await picker.FilePicker.platform.pickFiles(
        type: allowedExtensions != null 
            ? picker.FileType.custom 
            : picker.FileType.any,
        allowedExtensions: allowedExtensions,
        allowMultiple: true,
        dialogTitle: dialogTitle,
      );
      
      return result?.files.map((file) => file.path!).toList();
    }
  }
  
  /// Pick a directory and return its path
  static Future<String?> pickDirectory({
    String? dialogTitle,
  }) async {
    // Use file_selector for desktop platforms
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final directory = await getDirectoryPath(
        confirmButtonText: 'Select',
      );
      
      return directory;
    } 
    // Use file_picker for mobile platforms
    else {
      final result = await picker.FilePicker.platform.getDirectoryPath(
        dialogTitle: dialogTitle,
      );
      
      return result;
    }
  }
}
