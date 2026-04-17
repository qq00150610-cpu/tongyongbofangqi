import 'package:uuid/uuid.dart';

/// 媒体类型枚举
enum MediaType {
  /// 音频文件
  audio,
  
  /// 视频文件
  video,
  
  /// 未知类型
  unknown,
}

/// 媒体项数据模型
/// 
/// 代表一个媒体文件的所有相关信息
class MediaItem {
  /// 唯一标识符
  final String id;
  
  /// 文件路径
  final String path;
  
  /// 显示名称（不含扩展名）
  final String name;
  
  /// 文件扩展名
  final String extension;
  
  /// 媒体类型（音频/视频）
  final MediaType type;
  
  /// 文件大小（字节）
  final int size;
  
  /// 时长（毫秒）
  final Duration? duration;
  
  /// 缩略图路径（视频文件）
  final String? thumbnail;
  
  /// 上次播放位置（毫秒）
  final int? lastPosition;
  
  /// 上次播放时间戳
  final DateTime? lastPlayed;
  
  /// 创建时间
  final DateTime createdAt;
  
  /// 构造函数
  MediaItem({
    String? id,
    required this.path,
    required this.name,
    required this.extension,
    required this.type,
    this.size = 0,
    this.duration,
    this.thumbnail,
    this.lastPosition,
    this.lastPlayed,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();
  
  /// 从文件路径创建MediaItem
  factory MediaItem.fromPath(String filePath) {
    final pathParts = filePath.split('/');
    final fileNameWithExt = pathParts.last;
    final lastDotIndex = fileNameWithExt.lastIndexOf('.');
    
    final name = lastDotIndex > 0 
        ? fileNameWithExt.substring(0, lastDotIndex) 
        : fileNameWithExt;
    final extension = lastDotIndex > 0 
        ? fileNameWithExt.substring(lastDotIndex + 1).toLowerCase() 
        : '';
    
    return MediaItem(
      path: filePath,
      name: name,
      extension: extension,
      type: _getMediaType(extension),
    );
  }
  
  /// 根据扩展名判断媒体类型
  static MediaType _getMediaType(String extension) {
    // 音频格式列表
    const audioExtensions = [
      'mp3', 'aac', 'flac', 'wav', 'ogg', 'wma', 'opus', 'alac', 
      'm4a', 'aiff', 'ape', 'opus', 'ac3', 'dts'
    ];
    
    // 视频格式列表
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
  
  /// 判断是否为支持的格式
  static bool isSupported(String extension) {
    return _getMediaType(extension.toLowerCase()) != MediaType.unknown;
  }
  
  /// 支持的所有音频扩展名
  static const List<String> supportedAudioExtensions = [
    'mp3', 'aac', 'flac', 'wav', 'ogg', 'wma', 'opus', 'alac', 
    'm4a', 'aiff', 'ape', 'opus', 'ac3', 'dts'
  ];
  
  /// 支持的所有视频扩展名
  static const List<String> supportedVideoExtensions = [
    'mp4', 'mkv', 'avi', 'mov', 'webm', '3gp', 'ts', 'm2ts',
    'flv', 'wmv', 'm4v', 'mpeg', 'mpg', 'vob', 'ogv'
  ];
  
  /// 完整的支持格式列表
  static List<String> get allSupportedExtensions => 
      [...supportedAudioExtensions, ...supportedVideoExtensions];
  
  /// 复制并修改属性
  MediaItem copyWith({
    String? id,
    String? path,
    String? name,
    String? extension,
    MediaType? type,
    int? size,
    Duration? duration,
    String? thumbnail,
    int? lastPosition,
    DateTime? lastPlayed,
    DateTime? createdAt,
  }) {
    return MediaItem(
      id: id ?? this.id,
      path: path ?? this.path,
      name: name ?? this.name,
      extension: extension ?? this.extension,
      type: type ?? this.type,
      size: size ?? this.size,
      duration: duration ?? this.duration,
      thumbnail: thumbnail ?? this.thumbnail,
      lastPosition: lastPosition ?? this.lastPosition,
      lastPlayed: lastPlayed ?? this.lastPlayed,
      createdAt: createdAt ?? this.createdAt,
    );
  }
  
  /// 转换为Map（用于存储）
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'path': path,
      'name': name,
      'extension': extension,
      'type': type.index,
      'size': size,
      'duration': duration?.inMilliseconds,
      'thumbnail': thumbnail,
      'lastPosition': lastPosition,
      'lastPlayed': lastPlayed?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
  
  /// 从Map恢复（用于读取）
  factory MediaItem.fromJson(Map<String, dynamic> json) {
    return MediaItem(
      id: json['id'] as String,
      path: json['path'] as String,
      name: json['name'] as String,
      extension: json['extension'] as String,
      type: MediaType.values[json['type'] as int],
      size: json['size'] as int? ?? 0,
      duration: json['duration'] != null 
          ? Duration(milliseconds: json['duration'] as int) 
          : null,
      thumbnail: json['thumbnail'] as String?,
      lastPosition: json['lastPosition'] as int?,
      lastPlayed: json['lastPlayed'] != null 
          ? DateTime.parse(json['lastPlayed'] as String) 
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MediaItem && other.id == id;
  }
  
  @override
  int get hashCode => id.hashCode;
  
  @override
  String toString() {
    return 'MediaItem(id: $id, name: $name, type: $type, path: $path)';
  }
}
