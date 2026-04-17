import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/playback_state.dart';
import '../models/media_item.dart';
import '../services/player_service.dart';

/// 播放器Provider
/// 
/// 管理播放器的所有状态，包括：
/// - 当前媒体
/// - 播放状态
/// - 播放位置
/// - 音量
/// - 播放速度
/// - 播放模式
class PlayerNotifier extends StateNotifier<PlaybackState> {
  final PlayerService _playerService;
  
  PlayerNotifier(this._playerService) : super(PlaybackState.initial) {
    _init();
  }
  
  /// 初始化监听
  void _init() {
    // 添加状态监听
    _playerService.addStateListener((playbackState) {
      state = playbackState;
    });
    
    // 添加完成监听
    _playerService.addCompletedListener(() {
      // 播放完成时可以在这里触发自动播放下一个
    });
  }
  
  /// 播放指定媒体
  Future<void> play(MediaItem media) async {
    await _playerService.play(media);
    state = state.copyWith(status: PlaybackStatus.loading);
  }
  
  /// 暂停
  Future<void> pause() async {
    await _playerService.pause();
  }
  
  /// 继续播放
  Future<void> resume() async {
    await _playerService.resume();
  }
  
  /// 停止
  Future<void> stop() async {
    await _playerService.stop();
  }
  
  /// 切换播放/暂停
  Future<void> togglePlayPause() async {
    if (state.isPlaying) {
      await pause();
    } else {
      await resume();
    }
  }
  
  /// 跳转到指定位置
  Future<void> seekTo(Duration position) async {
    await _playerService.seekTo(position);
  }
  
  /// 跳转到百分比位置
  Future<void> seekToPercent(double percent) async {
    final position = Duration(
      milliseconds: (state.duration.inMilliseconds * percent).toInt(),
    );
    await seekTo(position);
  }
  
  /// 快进
  Future<void> skipForward({double seconds = 10}) async {
    await _playerService.skipForward(seconds: seconds);
  }
  
  /// 快退
  Future<void> skipBackward({double seconds = 10}) async {
    await _playerService.skipBackward(seconds: seconds);
  }
  
  /// 设置音量
  Future<void> setVolume(double volume) async {
    await _playerService.setVolume(volume);
  }
  
  /// 增加音量
  Future<void> increaseVolume({double delta = 0.1}) async {
    await _playerService.increaseVolume(delta: delta);
  }
  
  /// 减少音量
  Future<void> decreaseVolume({double delta = 0.1}) async {
    await _playerService.decreaseVolume(delta: delta);
  }
  
  /// 设置播放速度
  Future<void> setSpeed(double speed) async {
    await _playerService.setSpeed(speed);
  }
  
  /// 设置循环播放
  Future<void> setLooping(bool looping) async {
    await _playerService.setLooping(looping);
  }
  
  /// 获取当前播放位置
  Duration get position => _playerService.position;
  
  /// 获取总时长
  Duration get duration => _playerService.duration;
  
  /// 获取当前是否正在播放
  bool get isPlaying => _playerService.isPlaying;
  
  @override
  void dispose() {
    _playerService.removeStateListener((_) {});
    _playerService.removeCompletedListener(() {});
    super.dispose();
  }
}

/// 播放器Provider
final playerProvider = StateNotifierProvider<PlayerNotifier, PlaybackState>((ref) {
  return PlayerNotifier(PlayerService.instance);
});

/// 当前媒体Provider
final currentMediaProvider = Provider<MediaItem?>((ref) {
  return PlayerService.instance.currentMedia;
});

/// 播放进度Provider (0.0 - 1.0)
final progressProvider = Provider<double>((ref) {
  final state = ref.watch(playerProvider);
  if (state.duration.inMilliseconds == 0) return 0.0;
  return state.position.inMilliseconds / state.duration.inMilliseconds;
});
