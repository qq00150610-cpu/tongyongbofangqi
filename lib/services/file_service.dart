import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/media_item.dart';

/// 文件管理服务
/// 
/// 负责文件系统的所有操作：
/// - 扫描本地媒体文件
/// - 获取文件元数据
/// - 文件过滤
/// - 文件选择
class FileService {
  // 单例模式
  static final FileService instance = FileService._internal();
  factory FileService() => instance;
  FileService._internal();
  
  /// 扫描指定目录下的所有媒体文件
  Future<List<MediaItem>> scanDirectory(String directoryPath) async {
    final List<MediaItem> mediaFiles = [];
    
    try {
      final directory = Directory(directoryPath);
      if (!await directory.exists()) {
        debugPrint('Directory does not exist: $directoryPath');
        return mediaFiles;
      }
      
      // 使用递归遍历目录
      await for (final entity in directory.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          final mediaItem = await _fileToMediaItem(entity);
          if (mediaItem != null) {
            mediaFiles.add(mediaItem);
          }
        }
      }
      
      debugPrint('Found ${mediaFiles.length} media files in $directoryPath');
    } catch (e) {
      debugPrint('Error scanning directory: $e');
    }
    
    return mediaFiles;
  }
  
  /// 将文件转换为MediaItem
  Future<MediaItem?> _fileToMediaItem(File file) async {
    try {
      final extension = path.extension(file.path).toLowerCase().replaceFirst('.', '');
      
      // 检查是否为支持的格式
      if (!MediaItem.isSupported(extension)) {
        return null;
      }
      
      // 获取文件信息
      final stat = await file.stat();
      
      return MediaItem(
        path: file.path,
        name: path.basenameWithoutExtension(file.path),
        extension: extension,
        type: MediaItem._getMediaTypeFromExtension(extension),
        size: stat.size,
        createdAt: stat.modified,
      );
    } catch (e) {
      debugPrint('Error processing file: $e');
      return null;
    }
  }
  
  /// 获取媒体类型（根据扩展名）
  static MediaType _getMediaTypeFromExtension(String extension) {
    const audioExtensions = [
      'mp3', 'aac', 'flac', 'wav', 'ogg', 'wma', 'opus', 'alac', 
      'm4a', 'aiff', 'ape', 'ac3', 'dts'
    ];
    
    const videoExtensions = [
      'mp4', 'mkv', 'avi', 'mov', 'webm', '3gp', 'ts', 'm2ts',
      'flv', 'wmv', 'm4v', 'mpeg', 'mpg', 'vob', 'ogv'
    ];
    
    if (audioExtensions.contains(extension)) {
      return MediaType.audio;
    } else if (videoExtensions.contains(extension)) {
      return MediaType.video;
    }
    return MediaType.unknown;
  }
  
  /// 使用文件选择器选择媒体文件
  Future<List<MediaItem>?> pickMediaFiles({
    bool allowMultiple = true,
    List<String>? allowedExtensions,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: allowedExtensions != null ? FileType.custom : FileType.media,
        allowedExtensions: allowedExtensions ?? MediaItem.allSupportedExtensions,
        allowMultiple: allowMultiple,
      );
      
      if (result == null || result.files.isEmpty) {
        return null;
      }
      
      final List<MediaItem> mediaItems = [];
      
      for (final file in result.files) {
        if (file.path != null) {
          mediaItems.add(MediaItem.fromPath(file.path!));
        }
      }
      
      return mediaItems;
    } catch (e) {
      debugPrint('Error picking files: $e');
      return null;
    }
  }
  
  /// 选择音频文件
  Future<List<MediaItem>?> pickAudioFiles({bool allowMultiple = true}) async {
    return pickMediaFiles(
      allowMultiple: allowMultiple,
      allowedExtensions: MediaItem.supportedAudioExtensions,
    );
  }
  
  /// 选择视频文件
  Future<List<MediaItem>?> pickVideoFiles({bool allowMultiple = true}) async {
    return pickMediaFiles(
      allowMultiple: allowMultiple,
      allowedExtensions: MediaItem.supportedVideoExtensions,
    );
  }
  
  /// 选择文件夹
  Future<String?> pickDirectory() async {
    try {
      final result = await FilePicker.platform.getDirectoryPath();
      return result;
    } catch (e) {
      debugPrint('Error picking directory: $e');
      return null;
    }
  }
  
  /// 获取应用文档目录
  Future<String> getAppDocumentsPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }
  
  /// 获取应用缓存目录
  Future<String> getAppCachePath() async {
    final directory = await getTemporaryDirectory();
    return directory.path;
  }
  
  /// 获取外部存储目录（Android）
  Future<List<String>> getExternalStoragePaths() async {
    final List<String> paths = [];
    
    if (Platform.isAndroid) {
      // 常见的媒体目录
      final commonDirs = [
        '/storage/emulated/0/Download',
        '/storage/emulated/0/DCIM',
        '/storage/emulated/0/Movies',
        '/storage/emulated/0/Music',
        '/storage/emulated/0/Pictures',
        '/storage/emulated/0/Documents',
      ];
      
      for (final dirPath in commonDirs) {
        final dir = Directory(dirPath);
        if (await dir.exists()) {
          paths.add(dirPath);
        }
      }
    }
    
    return paths;
  }
  
  /// 检查文件是否存在
  Future<bool> fileExists(String filePath) async {
    return File(filePath).exists();
  }
  
  /// 获取文件大小（格式化）
  Future<String> getFormattedFileSize(String filePath) async {
    try {
      final file = File(filePath);
      final stat = await file.stat();
      return _formatFileSize(stat.size);
    } catch (e) {
      return 'Unknown';
    }
  }
  
  /// 格式化文件大小
  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }
  
  /// 获取文件扩展名
  String getFileExtension(String filePath) {
    return path.extension(filePath).toLowerCase().replaceFirst('.', '');
  }
  
  /// 判断是否为音频文件
  bool isAudioFile(String extension) {
    return MediaItem.supportedAudioExtensions.contains(extension.toLowerCase());
  }
  
  /// 判断是否为视频文件
  bool isVideoFile(String extension) {
    return MediaItem.supportedVideoExtensions.contains(extension.toLowerCase());
  }
  
  /// 获取文件图标类型
  String getMediaIcon(MediaType type) {
    switch (type) {
      case MediaType.audio:
        return '🎵';
      case MediaType.video:
        return '🎬';
      case MediaType.unknown:
        return '📄';
    }
  }
}
