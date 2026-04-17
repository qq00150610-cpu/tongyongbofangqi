import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/playlist_provider.dart';
import '../providers/player_provider.dart';
import '../models/media_item.dart';
import '../models/playback_state.dart';
import '../widgets/media_list_tile.dart';
import 'player_screen.dart';

/// 播放列表页面
/// 
/// 显示和管理播放列表，包括：
/// - 当前播放列表
/// - 播放历史
/// - 播放模式切换
class PlaylistScreen extends ConsumerStatefulWidget {
  const PlaylistScreen({super.key});

  @override
  ConsumerState<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends ConsumerState<PlaylistScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// 播放指定媒体
  void _playMedia(MediaItem media) {
    ref.read(playlistProvider.notifier).playMedia(media);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PlayerScreen(),
      ),
    );
  }

  /// 切换播放模式
  void _togglePlaybackMode() {
    ref.read(playlistProvider.notifier).togglePlaybackMode();
    
    // 显示当前模式
    final mode = ref.read(playlistProvider).playbackMode;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mode.displayName),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  /// 播放上一个
  void _playPrevious() {
    ref.read(playlistProvider.notifier).playPrevious();
  }

  /// 播放下一个
  void _playNext() {
    ref.read(playlistProvider.notifier).playNext();
  }

  /// 清空播放列表
  void _clearPlaylist() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空播放列表'),
        content: const Text('确定要清空播放列表吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              ref.read(playlistProvider.notifier).clearPlaylist();
              Navigator.pop(context);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 清空历史记录
  void _clearHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空历史记录'),
        content: const Text('确定要清空播放历史吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              ref.read(playlistProvider.notifier).clearHistory();
              Navigator.pop(context);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final playlistState = ref.watch(playlistProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('播放列表'),
        
        // 标签栏
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              text: '播放列表 (${playlistState.length})',
              icon: const Icon(Icons.queue_music),
            ),
            Tab(
              text: '历史 (${playlistState.history.length})',
              icon: const Icon(Icons.history),
            ),
          ],
        ),
        
        actions: [
          // 播放模式按钮
          IconButton(
            icon: Text(
              playlistState.playbackMode.icon,
              style: const TextStyle(fontSize: 24),
            ),
            tooltip: playlistState.playbackMode.displayName,
            onPressed: _togglePlaybackMode,
          ),
          
          // 更多选项
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'clear_playlist':
                  _clearPlaylist();
                  break;
                case 'clear_history':
                  _clearHistory();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear_playlist',
                child: Row(
                  children: [
                    Icon(Icons.clear_all),
                    SizedBox(width: 8),
                    Text('清空播放列表'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_history',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep),
                    SizedBox(width: 8),
                    Text('清空历史记录'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      
      body: TabBarView(
        controller: _tabController,
        children: [
          // 播放列表标签
          _buildPlaylistTab(playlistState),
          
          // 历史标签
          _buildHistoryTab(playlistState),
        ],
      ),
      
      // 底部迷你播放器
      bottomNavigationBar: _buildMiniPlayer(playlistState),
    );
  }

  /// 构建播放列表标签
  Widget _buildPlaylistTab(PlaylistState state) {
    if (state.isEmpty) {
      return _buildEmptyState(
        icon: Icons.queue_music,
        title: '播放列表为空',
        subtitle: '从文件浏览添加音乐或视频',
      );
    }

    return ReorderableListView.builder(
      itemCount: state.length,
      onReorder: (oldIndex, newIndex) {
        ref.read(playlistProvider.notifier).moveItem(oldIndex, newIndex);
      },
      itemBuilder: (context, index) {
        final media = state.playlist[index];
        final isPlaying = index == state.currentIndex;
        
        return Dismissible(
          key: Key(media.id),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (direction) {
            ref.read(playlistProvider.notifier).removeFromPlaylist(media);
          },
          child: MediaListTile(
            key: ValueKey(media.id),
            media: media,
            isPlaying: isPlaying,
            showDuration: true,
            onTap: () => _playMedia(media),
            trailing: ReorderableDragStartListener(
              index: index,
              child: const Icon(Icons.drag_handle),
            ),
          ),
        );
      },
    );
  }

  /// 构建历史标签
  Widget _buildHistoryTab(PlaylistState state) {
    if (state.history.isEmpty) {
      return _buildEmptyState(
        icon: Icons.history,
        title: '暂无播放历史',
        subtitle: '播放过的媒体将显示在这里',
      );
    }

    return ListView.builder(
      itemCount: state.history.length,
      itemBuilder: (context, index) {
        final media = state.history[index];
        
        return MediaListTile(
          media: media,
          showDuration: true,
          subtitle: media.lastPlayed != null
              ? '上次播放: ${_formatDate(media.lastPlayed!)}'
              : null,
          onTap: () => _playMedia(media),
          trailing: IconButton(
            icon: const Icon(Icons.playlist_add),
            onPressed: () {
              ref.read(playlistProvider.notifier).addToPlaylist(media);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('已添加到播放列表: ${media.name}'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// 构建空状态
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  /// 底部迷你播放器
  Widget _buildMiniPlayer(PlaylistState state) {
    final currentMedia = state.currentMedia;
    if (currentMedia == null) {
      return const SizedBox.shrink();
    }

    final playbackState = ref.watch(playerProvider);
    
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 进度条
          LinearProgressIndicator(
            value: playbackState.progress,
            backgroundColor: Colors.grey.withOpacity(0.2),
          ),
          
          // 控制栏
          ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                currentMedia.type == MediaType.video
                    ? Icons.videocam
                    : Icons.music_note,
                color: Theme.of(context).primaryColor,
              ),
            ),
            title: Text(
              currentMedia.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${playbackState.positionString} / ${playbackState.durationString}',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.skip_previous),
                  onPressed: state.hasPrevious ? _playPrevious : null,
                ),
                IconButton(
                  icon: Icon(
                    playbackState.isPlaying ? Icons.pause : Icons.play_arrow,
                  ),
                  onPressed: () {
                    ref.read(playerProvider.notifier).togglePlayPause();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next),
                  onPressed: state.hasNext ? _playNext : null,
                ),
              ],
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const PlayerScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// 格式化日期
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}分钟前';
      }
      return '${difference.inHours}小时前';
    } else if (difference.inDays == 1) {
      return '昨天';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return '${date.month}/${date.day}';
    }
  }
}
