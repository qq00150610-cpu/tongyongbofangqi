import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../models/media_item.dart';
import '../models/playback_state.dart';

/// 播放器核心服务
/// 
/// 负责所有音视频播放的核心功能，包括：
/// - 播放器初始化和销毁
/// - 播放控制（播放、暂停、停止、跳转）
/// - 快进快退
/// - 音量控制
/// - 倍速播放
/// - 播放状态监听
class PlayerService {
  // 单例模式
  static final PlayerService instance = PlayerService._internal();
  factory PlayerService() => instance;
  PlayerService._internal();
  
  /// Flutter播放器实例
  late final Player player;
  
  /// 视频控制器（用于视频渲染）
  late final VideoController videoController;
  
  /// 当前播放的媒体项
  MediaItem? currentMedia;
  
  /// 播放状态流订阅
  StreamSubscription<PlaybackState>? _playbackSubscription;
  
  /// 错误流订阅
  StreamSubscription<String>? _errorSubscription;
  
  /// 完成播放流订阅
  StreamSubscription<void>? _completedSubscription;
  
  /// 当前播放状态
  PlaybackState _playbackState = PlaybackState.initial;
  PlaybackState get playbackState => _playbackState;
  
  /// 播放状态变更监听器列表
  final List<void Function(PlaybackState)> _stateListeners = [];
  
  /// 播放完成监听器列表
  final List<void Function()> _completedListeners = [];
  
  /// 是否已初始化
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  
  /// 初始化播放器
  Future<void> init() async {
    if (_isInitialized) return;
    
    try {
      // 创建播放器实例
      player = Player();
      
      // 创建视频控制器
      videoController = VideoController(player);
      
      // 监听播放状态变化
      _playbackSubscription = player.stream.playbackState.listen(_handlePlaybackState);
      
      // 监听错误
      _errorSubscription = player.stream.error.listen(_handleError);
      
      // 监听播放完成
      _completedSubscription = player.stream.completed.listen(_handleCompleted);
      
      _isInitialized = true;
      debugPrint('PlayerService initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize PlayerService: $e');
      rethrow;
    }
  }
  
  /// 处理播放状态变化
  void _handlePlaybackState(media_kit.PlaybackState state) {
    PlaybackStatus status;
    
    if (state.loading) {
      status = PlaybackStatus.loading;
    } else if (state.buffering) {
      status = PlaybackStatus.buffering;
    } else if (state.playing) {
      status = PlaybackStatus.playing;
    } else if (state.completed) {
      status = PlaybackStatus.completed;
    } else {
      status = _playbackState.status;
    }
    
    _playbackState = _playbackState.copyWith(
      status: status,
      position: player.state.position,
      duration: player.state.duration,
      buffer: player.state.buffer,
      initialized: true,
    );
    
    // 通知所有监听器
    _notifyStateListeners();
  }
  
  /// 处理错误
  void _handleError(String error) {
    _playbackState = _playbackState.copyWith(
      status: PlaybackStatus.error,
      errorMessage: error,
    );
    _notifyStateListeners();
    debugPrint('Player error: $error');
  }
  
  /// 处理播放完成
  void _handleCompleted(void _) {
    _playbackState = _playbackState.copyWith(status: PlaybackStatus.completed);
    _notifyStateListeners();
    
    // 通知完成监听器
    for (final listener in _completedListeners) {
      listener();
    }
  }
  
  /// 通知状态监听器
  void _notifyStateListeners() {
    for (final listener in _stateListeners) {
      listener(_playbackState);
    }
  }
  
  /// 播放指定媒体
  Future<void> play(MediaItem media) async {
    if (!_isInitialized) {
      await init();
    }
    
    try {
      currentMedia = media;
      _playbackState = _playbackState.copyWith(
        status: PlaybackStatus.loading,
        position: Duration.zero,
      );
      _notifyStateListeners();
      
      // 打开媒体文件
      await player.open(Media(media.path));
      
      // 开始播放
      await player.play();
      
      debugPrint('Playing: ${media.name}');
    } catch (e) {
      debugPrint('Failed to play: $e');
      _playbackState = _playbackState.copyWith(
        status: PlaybackStatus.error,
        errorMessage: e.toString(),
      );
      _notifyStateListeners();
    }
  }
  
  /// 继续播放
  Future<void> resume() async {
    await player.play();
  }
  
  /// 暂停播放
  Future<void> pause() async {
    await player.pause();
  }
  
  /// 停止播放
  Future<void> stop() async {
    await player.stop();
    currentMedia = null;
    _playbackState = PlaybackState.initial;
    _notifyStateListeners();
  }
  
  /// 跳转到指定位置
  Future<void> seekTo(Duration position) async {
    await player.seek(position);
  }
  
  /// 快进指定秒数
  Future<void> skipForward({double seconds = 10}) async {
    final newPosition = _playbackState.position + Duration(
      milliseconds: (seconds * 1000).toInt(),
    );
    
    // 不能超过总时长
    final clampedPosition = newPosition > _playbackState.duration
        ? _playbackState.duration
        : newPosition;
    
    await seekTo(clampedPosition);
  }
  
  /// 快退指定秒数
  Future<void> skipBackward({double seconds = 10}) async {
    final newPosition = _playbackState.position - Duration(
      milliseconds: (seconds * 1000).toInt(),
    );
    
    // 不能小于0
    final clampedPosition = newPosition < Duration.zero
        ? Duration.zero
        : newPosition;
    
    await seekTo(clampedPosition);
  }
  
  /// 设置音量 (0.0 - 1.0)
  Future<void> setVolume(double volume) async {
    final clampedVolume = volume.clamp(0.0, 1.0);
    await player.setVolume(clampedVolume * 100);
    _playbackState = _playbackState.copyWith(volume: clampedVolume);
    _notifyStateListeners();
  }
  
  /// 增加音量
  Future<void> increaseVolume({double delta = 0.1}) async {
    await setVolume(_playbackState.volume + delta);
  }
  
  /// 减少音量
  Future<void> decreaseVolume({double delta = 0.1}) async {
    await setVolume(_playbackState.volume - delta);
  }
  
  /// 设置播放速度 (0.5 - 2.0)
  Future<void> setSpeed(double speed) async {
    final clampedSpeed = speed.clamp(0.5, 2.0);
    await player.setRate(clampedSpeed);
    _playbackState = _playbackState.copyWith(speed: clampedSpeed);
    _notifyStateListeners();
  }
  
  /// 设置循环播放
  Future<void> setLooping(bool looping) async {
    await player.setPlaylistMode(looping ? PlaylistMode.loop : PlaylistMode.none);
    _playbackState = _playbackState.copyWith(looping: looping);
    _notifyStateListeners();
  }
  
  /// 切换播放/暂停状态
  Future<void> togglePlayPause() async {
    if (_playbackState.isPlaying) {
      await pause();
    } else {
      await resume();
    }
  }
  
  /// 添加播放状态监听器
  void addStateListener(void Function(PlaybackState) listener) {
    _stateListeners.add(listener);
  }
  
  /// 移除播放状态监听器
  void removeStateListener(void Function(PlaybackState) listener) {
    _stateListeners.remove(listener);
  }
  
  /// 添加播放完成监听器
  void addCompletedListener(void Function() listener) {
    _completedListeners.add(listener);
  }
  
  /// 移除播放完成监听器
  void removeCompletedListener(void Function() listener) {
    _completedListeners.remove(listener);
  }
  
  /// 获取当前播放位置
  Duration get position => player.state.position;
  
  /// 获取总时长
  Duration get duration => player.state.duration;
  
  /// 获取当前是否正在播放
  bool get isPlaying => player.state.playing;
  
  /// 销毁播放器
  Future<void> dispose() async {
    _playbackSubscription?.cancel();
    _errorSubscription?.cancel();
    _completedSubscription?.cancel();
    _stateListeners.clear();
    _completedListeners.clear();
    
    await player.dispose();
    _isInitialized = false;
    debugPrint('PlayerService disposed');
  }
}
