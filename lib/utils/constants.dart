/// 应用常量定义
class AppConstants {
  AppConstants._();
  
  // ==================== 应用信息 ====================
  
  /// 应用名称
  static const String appName = '通用播放器';
  
  /// 应用版本
  static const String appVersion = '1.0.0';
  
  /// 应用ID
  static const String appId = 'com.universal.player';
  
  // ==================== 播放设置 ====================
  
  /// 默认快进/快退秒数
  static const double defaultSeekSeconds = 10.0;
  
  /// 最小播放速度
  static const double minPlaybackSpeed = 0.5;
  
  /// 最大播放速度
  static const double maxPlaybackSpeed = 2.0;
  
  /// 默认音量
  static const double defaultVolume = 1.0;
  
  /// 音量调节步进
  static const double volumeStep = 0.1;
  
  // ==================== 定时关闭选项 ====================
  
  /// 定时关闭选项（分钟）
  static const List<int> sleepTimerOptions = [
    0,    // 关闭
    15,
    30,
    45,
    60,
    90,
    120,
  ];
  
  // ==================== 播放速度选项 ====================
  
  /// 播放速度选项
  static const List<double> playbackSpeedOptions = [
    0.5,
    0.75,
    1.0,
    1.25,
    1.5,
    1.75,
    2.0,
  ];
  
  // ==================== UI设置 ====================
  
  /// 迷你播放器高度
  static const double miniPlayerHeight = 72.0;
  
  /// 底部导航栏高度
  static const double bottomNavHeight = 80.0;
  
  /// 动画时长
  static const Duration animationDuration = Duration(milliseconds: 300);
  
  /// 短动画时长
  static const Duration shortAnimationDuration = Duration(milliseconds: 150);
  
  // ==================== 文件设置 ====================
  
  /// 最大历史记录数
  static const int maxHistoryCount = 100;
  
  /// 最大播放列表数
  static const int maxPlaylistCount = 1000;
  
  /// 支持的文件扩展名
  static const List<String> supportedAudioExtensions = [
    'mp3', 'aac', 'flac', 'wav', 'ogg', 'wma', 'opus', 'alac', 
    'm4a', 'aiff', 'ape', 'ac3', 'dts'
  ];
  
  static const List<String> supportedVideoExtensions = [
    'mp4', 'mkv', 'avi', 'mov', 'webm', '3gp', 'ts', 'm2ts',
    'flv', 'wmv', 'm4v', 'mpeg', 'mpg', 'vob', 'ogv'
  ];
}

/// 平台相关常量
class PlatformConstants {
  PlatformConstants._();
  
  // Android
  static const int androidMinSdkVersion = 21;
  static const int androidTargetSdkVersion = 34;
  
  // iOS
  static const String iosMinVersion = '12.0';
  
  // 权限相关
  static const List<String> androidAudioPermissions = [
    'READ_MEDIA_AUDIO',
    'READ_EXTERNAL_STORAGE',
  ];
  
  static const List<String> androidVideoPermissions = [
    'READ_MEDIA_VIDEO',
    'READ_EXTERNAL_STORAGE',
  ];
}
