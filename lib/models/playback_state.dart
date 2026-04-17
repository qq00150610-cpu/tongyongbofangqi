/// 播放状态枚举
enum PlaybackStatus {
  /// 空闲状态，未播放任何内容
  idle,
  
  /// 正在加载媒体
  loading,
  
  /// 正在缓冲
  buffering,
  
  /// 正在播放
  playing,
  
  /// 已暂停
  paused,
  
  /// 已停止
  stopped,
  
  /// 播放完成
  completed,
  
  /// 发生错误
  error,
}

/// 播放状态数据模型
/// 
/// 记录播放器当前的完整状态信息
class PlaybackState {
  /// 当前播放状态
  final PlaybackStatus status;
  
  /// 当前播放位置（毫秒）
  final Duration position;
  
  /// 媒体总时长（毫秒）
  final Duration duration;
  
  /// 缓冲进度（0.0 - 1.0）
  final double buffer;
  
  /// 播放速度（0.5 - 2.0）
  final double speed;
  
  /// 音量（0.0 - 1.0）
  final double volume;
  
  /// 是否循环播放
  final bool looping;
  
  /// 错误信息（如果有）
  final String? errorMessage;
  
  /// 播放器是否就绪
  final bool initialized;
  
  /// 构造函数
  const PlaybackState({
    this.status = PlaybackStatus.idle,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.buffer = 0.0,
    this.speed = 1.0,
    this.volume = 1.0,
    this.looping = false,
    this.errorMessage,
    this.initialized = false,
  });
  
  /// 初始状态
  static const PlaybackState initial = PlaybackState();
  
  /// 是否正在播放
  bool get isPlaying => status == PlaybackStatus.playing;
  
  /// 是否已暂停
  bool get isPaused => status == PlaybackStatus.paused;
  
  /// 是否在缓冲中
  bool get isBuffering => status == PlaybackStatus.buffering;
  
  /// 是否空闲
  bool get isIdle => status == PlaybackStatus.idle;
  
  /// 是否有错误
  bool get hasError => status == PlaybackStatus.error;
  
  /// 是否已停止或完成
  bool get isStopped => 
      status == PlaybackStatus.stopped || 
      status == PlaybackStatus.completed;
  
  /// 播放进度百分比（0.0 - 1.0）
  double get progress {
    if (duration.inMilliseconds == 0) return 0.0;
    return position.inMilliseconds / duration.inMilliseconds;
  }
  
  /// 剩余时间
  Duration get remaining => duration - position;
  
  /// 格式化当前时间为字符串 (HH:MM:SS 或 MM:SS)
  String get positionString {
    if (duration >= const Duration(hours: 1)) {
      return _formatDuration(position);
    }
    return _formatDurationShort(position);
  }
  
  /// 格式化总时长为字符串
  String get durationString {
    if (duration >= const Duration(hours: 1)) {
      return _formatDuration(duration);
    }
    return _formatDurationShort(duration);
  }
  
  /// 格式化剩余时间为字符串
  String get remainingString {
    return '-${_formatDurationShort(remaining)}';
  }
  
  /// 格式化时长 (HH:MM:SS)
  static String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }
  
  /// 格式化时长 (MM:SS)
  static String _formatDurationShort(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
  
  /// 复制并修改属性
  PlaybackState copyWith({
    PlaybackStatus? status,
    Duration? position,
    Duration? duration,
    double? buffer,
    double? speed,
    double? volume,
    bool? looping,
    String? errorMessage,
    bool? initialized,
  }) {
    return PlaybackState(
      status: status ?? this.status,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      buffer: buffer ?? this.buffer,
      speed: speed ?? this.speed,
      volume: volume ?? this.volume,
      looping: looping ?? this.looping,
      errorMessage: errorMessage,
      initialized: initialized ?? this.initialized,
    );
  }
  
  @override
  String toString() {
    return 'PlaybackState(status: $status, position: $position, '
        'duration: $duration, progress: ${(progress * 100).toStringAsFixed(1)}%)';
  }
}

/// 播放模式枚举
enum PlaybackMode {
  /// 顺序播放
  sequential,
  
  /// 列表循环
  loopList,
  
  /// 单曲循环
  loopSingle,
  
  /// 随机播放
  shuffle,
}

/// 扩展PlayMode的方法
extension PlaybackModeExtension on PlaybackMode {
  /// 获取模式显示名称
  String get displayName {
    switch (this) {
      case PlaybackMode.sequential:
        return '顺序播放';
      case PlaybackMode.loopList:
        return '列表循环';
      case PlaybackMode.loopSingle:
        return '单曲循环';
      case PlaybackMode.shuffle:
        return '随机播放';
    }
  }
  
  /// 获取模式图标
  String get icon {
    switch (this) {
      case PlaybackMode.sequential:
        return '➡️';
      case PlaybackMode.loopList:
        return '🔁';
      case PlaybackMode.loopSingle:
        return '🔂';
      case PlaybackMode.shuffle:
        return '🔀';
    }
  }
}
