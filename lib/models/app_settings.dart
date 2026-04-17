import 'package:flutter/material.dart';

/// 应用设置数据模型
/// 
/// 存储用户的所有偏好设置
class AppSettings {
  /// 主题模式
  final ThemeMode themeMode;
  
  /// 自动播放下一个
  final bool autoPlayNext;
  
  /// 记忆播放位置
  final bool rememberPosition;
  
  /// 定时关闭时间（分钟，0表示关闭）
  final int sleepTimerMinutes;
  
  /// 默认播放速度
  final double defaultPlaybackSpeed;
  
  /// 播放品质 (0: 自动, 1: 高, 2: 中, 3: 低)
  final int videoQuality;
  
  /// 是否显示播放速度
  final bool showSpeedIndicator;
  
  /// 滑动调节灵敏度（秒）
  final double seekSensitivity;
  
  /// 滑动调节音量灵敏度
  final double volumeSensitivity;
  
  /// 滑动调节亮度灵敏度
  final double brightnessSensitivity;
  
  /// 手势控制方向（true: 左侧调节亮度, false: 左侧调节进度）
  final bool leftSideControlsBrightness;
  
  /// 是否启用锁屏控制
  final bool lockScreenControl;
  
  /// 是否在WiFi下才加载缩略图
  final bool wifiOnlyThumbnails;
  
  /// 构造函数
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.autoPlayNext = true,
    this.rememberPosition = true,
    this.sleepTimerMinutes = 0,
    this.defaultPlaybackSpeed = 1.0,
    this.videoQuality = 0,
    this.showSpeedIndicator = true,
    this.seekSensitivity = 10.0,
    this.volumeSensitivity = 1.0,
    this.brightnessSensitivity = 1.0,
    this.leftSideControlsBrightness = true,
    this.lockScreenControl = true,
    this.wifiOnlyThumbnails = false,
  });
  
  /// 默认设置
  static const AppSettings defaultSettings = AppSettings();
  
  /// 复制并修改属性
  AppSettings copyWith({
    ThemeMode? themeMode,
    bool? autoPlayNext,
    bool? rememberPosition,
    int? sleepTimerMinutes,
    double? defaultPlaybackSpeed,
    int? videoQuality,
    bool? showSpeedIndicator,
    double? seekSensitivity,
    double? volumeSensitivity,
    double? brightnessSensitivity,
    bool? leftSideControlsBrightness,
    bool? lockScreenControl,
    bool? wifiOnlyThumbnails,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      autoPlayNext: autoPlayNext ?? this.autoPlayNext,
      rememberPosition: rememberPosition ?? this.rememberPosition,
      sleepTimerMinutes: sleepTimerMinutes ?? this.sleepTimerMinutes,
      defaultPlaybackSpeed: defaultPlaybackSpeed ?? this.defaultPlaybackSpeed,
      videoQuality: videoQuality ?? this.videoQuality,
      showSpeedIndicator: showSpeedIndicator ?? this.showSpeedIndicator,
      seekSensitivity: seekSensitivity ?? this.seekSensitivity,
      volumeSensitivity: volumeSensitivity ?? this.volumeSensitivity,
      brightnessSensitivity: brightnessSensitivity ?? this.brightnessSensitivity,
      leftSideControlsBrightness: leftSideControlsBrightness ?? this.leftSideControlsBrightness,
      lockScreenControl: lockScreenControl ?? this.lockScreenControl,
      wifiOnlyThumbnails: wifiOnlyThumbnails ?? this.wifiOnlyThumbnails,
    );
  }
  
  /// 转换为Map（用于存储）
  Map<String, dynamic> toJson() {
    return {
      'themeMode': themeMode.index,
      'autoPlayNext': autoPlayNext,
      'rememberPosition': rememberPosition,
      'sleepTimerMinutes': sleepTimerMinutes,
      'defaultPlaybackSpeed': defaultPlaybackSpeed,
      'videoQuality': videoQuality,
      'showSpeedIndicator': showSpeedIndicator,
      'seekSensitivity': seekSensitivity,
      'volumeSensitivity': volumeSensitivity,
      'brightnessSensitivity': brightnessSensitivity,
      'leftSideControlsBrightness': leftSideControlsBrightness,
      'lockScreenControl': lockScreenControl,
      'wifiOnlyThumbnails': wifiOnlyThumbnails,
    };
  }
  
  /// 从Map恢复（用于读取）
  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      themeMode: ThemeMode.values[json['themeMode'] as int? ?? 0],
      autoPlayNext: json['autoPlayNext'] as bool? ?? true,
      rememberPosition: json['rememberPosition'] as bool? ?? true,
      sleepTimerMinutes: json['sleepTimerMinutes'] as int? ?? 0,
      defaultPlaybackSpeed: (json['defaultPlaybackSpeed'] as num?)?.toDouble() ?? 1.0,
      videoQuality: json['videoQuality'] as int? ?? 0,
      showSpeedIndicator: json['showSpeedIndicator'] as bool? ?? true,
      seekSensitivity: (json['seekSensitivity'] as num?)?.toDouble() ?? 10.0,
      volumeSensitivity: (json['volumeSensitivity'] as num?)?.toDouble() ?? 1.0,
      brightnessSensitivity: (json['brightnessSensitivity'] as num?)?.toDouble() ?? 1.0,
      leftSideControlsBrightness: json['leftSideControlsBrightness'] as bool? ?? true,
      lockScreenControl: json['lockScreenControl'] as bool? ?? true,
      wifiOnlyThumbnails: json['wifiOnlyThumbnails'] as bool? ?? false,
    );
  }
  
  @override
  String toString() {
    return 'AppSettings(themeMode: $themeMode, autoPlayNext: $autoPlayNext, '
        'rememberPosition: $rememberPosition, sleepTimer: $sleepTimerMinutes min)';
  }
}

/// 播放品质选项
enum VideoQuality {
  auto,
  high,
  medium,
  low,
}

/// 扩展VideoQuality的方法
extension VideoQualityExtension on VideoQuality {
  /// 获取显示名称
  String get displayName {
    switch (this) {
      case VideoQuality.auto:
        return '自动';
      case VideoQuality.high:
        return '高 (1080p)';
      case VideoQuality.medium:
        return '中 (720p)';
      case VideoQuality.low:
        return '低 (480p)';
    }
  }
  
  /// 获取数值
  int get value => index;
}
