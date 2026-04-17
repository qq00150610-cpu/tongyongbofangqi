import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/media_item.dart';
import '../models/playback_state.dart';
import '../services/storage_service.dart';
import 'player_provider.dart';

/// 播放列表Provider
/// 
/// 管理播放列表的所有状态：
/// - 播放列表内容
/// - 当前播放索引
/// - 播放模式
/// - 播放历史
class PlaylistNotifier extends StateNotifier<PlaylistState> {
  final StorageService _storageService;
  final Ref _ref;
  
  PlaylistNotifier(this._storageService, this._ref) : super(PlaylistState.initial) {
    _init();
  }
  
  /// 初始化
  Future<void> _init() async {
    // 加载保存的播放列表
    final playlist = await _storageService.loadPlaylist();
    state = state.copyWith(
      playlist: playlist,
      history: await _storageService.loadHistory(),
    );
  }
  
  /// 添加媒体到播放列表
  Future<void> addToPlaylist(MediaItem media) async {
    // 检查是否已存在
    if (!state.playlist.contains(media)) {
      final newPlaylist = [...state.playlist, media];
      state = state.copyWith(playlist: newPlaylist);
      await _storageService.savePlaylist(newPlaylist);
    }
  }
  
  /// 添加多个媒体到播放列表
  Future<void> addAllToPlaylist(List<MediaItem> mediaList) async {
    final newItems = mediaList.where((item) => !state.playlist.contains(item));
    if (newItems.isNotEmpty) {
      final newPlaylist = [...state.playlist, ...newItems];
      state = state.copyWith(playlist: newPlaylist);
      await _storageService.savePlaylist(newPlaylist);
    }
  }
  
  /// 从播放列表移除
  Future<void> removeFromPlaylist(MediaItem media) async {
    final newPlaylist = state.playlist.where((item) => item.id != media.id).toList();
    state = state.copyWith(playlist: newPlaylist);
    await _storageService.savePlaylist(newPlaylist);
    
    // 如果移除的是当前播放的，调整索引
    if (state.currentIndex < newPlaylist.length) {
      // 索引保持不变
    } else if (newPlaylist.isNotEmpty) {
      state = state.copyWith(currentIndex: newPlaylist.length - 1);
    } else {
      state = state.copyWith(currentIndex: -1);
    }
  }
  
  /// 清空播放列表
  Future<void> clearPlaylist() async {
    state = state.copyWith(playlist: [], currentIndex: -1);
    await _storageService.clearPlaylist();
  }
  
  /// 播放指定媒体
  Future<void> playMedia(MediaItem media) async {
    // 查找媒体在列表中的位置
    final index = state.playlist.indexWhere((item) => item.id == media.id);
    
    if (index != -1) {
      // 列表中存在，直接播放
      state = state.copyWith(currentIndex: index);
    } else {
      // 列表中不存在，添加到列表并播放
      final newPlaylist = [...state.playlist, media];
      state = state.copyWith(
        playlist: newPlaylist,
        currentIndex: newPlaylist.length - 1,
      );
      await _storageService.savePlaylist(newPlaylist);
    }
    
    // 添加到历史记录
    await _addToHistory(media);
    
    // 开始播放
    await _ref.read(playerProvider.notifier).play(media);
  }
  
  /// 播放指定索引
  Future<void> playAtIndex(int index) async {
    if (index < 0 || index >= state.playlist.length) return;
    
    state = state.copyWith(currentIndex: index);
    await _addToHistory(state.playlist[index]);
    await _ref.read(playerProvider.notifier).play(state.playlist[index]);
  }
  
  /// 播放上一个
  Future<void> playPrevious() async {
    if (state.playlist.isEmpty) return;
    
    int newIndex;
    switch (state.playbackMode) {
      case PlaybackMode.shuffle:
        newIndex = _getRandomIndex();
        break;
      case PlaybackMode.loopList:
        newIndex = (state.currentIndex - 1) % state.playlist.length;
        if (newIndex < 0) newIndex = state.playlist.length - 1;
        break;
      case PlaybackMode.loopSingle:
      case PlaybackMode.sequential:
        if (state.currentIndex > 0) {
          newIndex = state.currentIndex - 1;
        } else {
          newIndex = 0;
        }
        break;
    }
    
    state = state.copyWith(currentIndex: newIndex);
    await _addToHistory(state.playlist[newIndex]);
    await _ref.read(playerProvider.notifier).play(state.playlist[newIndex]);
  }
  
  /// 播放下一个
  Future<void> playNext() async {
    if (state.playlist.isEmpty) return;
    
    int newIndex;
    switch (state.playbackMode) {
      case PlaybackMode.shuffle:
        newIndex = _getRandomIndex();
        break;
      case PlaybackMode.loopList:
        newIndex = (state.currentIndex + 1) % state.playlist.length;
        break;
      case PlaybackMode.loopSingle:
        newIndex = state.currentIndex;
        break;
      case PlaybackMode.sequential:
        if (state.currentIndex < state.playlist.length - 1) {
          newIndex = state.currentIndex + 1;
        } else {
          // 播放完成，停止
          await _ref.read(playerProvider.notifier).stop();
          return;
        }
        break;
    }
    
    state = state.copyWith(currentIndex: newIndex);
    await _addToHistory(state.playlist[newIndex]);
    await _ref.read(playerProvider.notifier).play(state.playlist[newIndex]);
  }
  
  /// 获取随机索引（排除当前）
  int _getRandomIndex() {
    if (state.playlist.length <= 1) return 0;
    
    int randomIndex;
    do {
      randomIndex = DateTime.now().millisecondsSinceEpoch % state.playlist.length;
    } while (randomIndex == state.currentIndex);
    
    return randomIndex;
  }
  
  /// 添加到历史记录
  Future<void> _addToHistory(MediaItem media) async {
    final newHistory = [media.copyWith(lastPlayed: DateTime.now())];
    
    // 移除重复项并添加到开头
    for (final item in state.history) {
      if (item.id != media.id && newHistory.length < 50) {
        newHistory.add(item);
      }
    }
    
    state = state.copyWith(history: newHistory);
    await _storageService.addToHistory(media);
  }
  
  /// 设置播放模式
  void setPlaybackMode(PlaybackMode mode) {
    state = state.copyWith(playbackMode: mode);
  }
  
  /// 切换播放模式
  void togglePlaybackMode() {
    final modes = PlaybackMode.values;
    final currentIndex = modes.indexOf(state.playbackMode);
    final nextIndex = (currentIndex + 1) % modes.length;
    state = state.copyWith(playbackMode: modes[nextIndex]);
  }
  
  /// 移动列表项
  void moveItem(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    
    final playlist = [...state.playlist];
    final item = playlist.removeAt(oldIndex);
    playlist.insert(newIndex, item);
    
    // 更新当前索引
    int currentIndex = state.currentIndex;
    if (currentIndex == oldIndex) {
      currentIndex = newIndex;
    } else if (oldIndex < currentIndex && newIndex >= currentIndex) {
      currentIndex--;
    } else if (oldIndex > currentIndex && newIndex <= currentIndex) {
      currentIndex++;
    }
    
    state = state.copyWith(
      playlist: playlist,
      currentIndex: currentIndex,
    );
    _storageService.savePlaylist(playlist);
  }
  
  /// 清空历史记录
  Future<void> clearHistory() async {
    state = state.copyWith(history: []);
    await _storageService.clearHistory();
  }
}

/// 播放列表状态
class PlaylistState {
  /// 播放列表
  final List<MediaItem> playlist;
  
  /// 当前播放索引
  final int currentIndex;
  
  /// 播放模式
  final PlaybackMode playbackMode;
  
  /// 播放历史
  final List<MediaItem> history;
  
  const PlaylistState({
    this.playlist = const [],
    this.currentIndex = -1,
    this.playbackMode = PlaybackMode.sequential,
    this.history = const [],
  });
  
  /// 初始状态
  static const PlaylistState initial = PlaylistState();
  
  /// 当前媒体
  MediaItem? get currentMedia {
    if (currentIndex >= 0 && currentIndex < playlist.length) {
      return playlist[currentIndex];
    }
    return null;
  }
  
  /// 是否有上一个
  bool get hasPrevious {
    if (playlist.isEmpty) return false;
    if (playbackMode == PlaybackMode.shuffle) return true;
    if (playbackMode == PlaybackMode.loopList) return true;
    return currentIndex > 0;
  }
  
  /// 是否有下一个
  bool get hasNext {
    if (playlist.isEmpty) return false;
    if (playbackMode == PlaybackMode.shuffle) return true;
    if (playbackMode == PlaybackMode.loopList) return true;
    return currentIndex < playlist.length - 1;
  }
  
  /// 是否为空
  bool get isEmpty => playlist.isEmpty;
  
  /// 数量
  int get length => playlist.length;
  
  PlaylistState copyWith({
    List<MediaItem>? playlist,
    int? currentIndex,
    PlaybackMode? playbackMode,
    List<MediaItem>? history,
  }) {
    return PlaylistState(
      playlist: playlist ?? this.playlist,
      currentIndex: currentIndex ?? this.currentIndex,
      playbackMode: playbackMode ?? this.playbackMode,
      history: history ?? this.history,
    );
  }
}

/// 播放列表Provider
final playlistProvider = StateNotifierProvider<PlaylistNotifier, PlaylistState>((ref) {
  return PlaylistNotifier(StorageService.instance, ref);
});

/// 当前媒体Provider
final currentPlaylistMediaProvider = Provider<MediaItem?>((ref) {
  return ref.watch(playlistProvider).currentMedia;
});

/// 播放模式Provider
final playbackModeProvider = Provider<PlaybackMode>((ref) {
  return ref.watch(playlistProvider).playbackMode;
});
