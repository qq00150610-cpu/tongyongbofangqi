import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/player_provider.dart';
import '../providers/playlist_provider.dart';
import '../models/playback_state.dart';
import 'player_screen.dart';

/// 迷你播放器组件
/// 
/// 显示在主页底部的迷你播放器条
class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playbackState = ref.watch(playerProvider);
    final currentMedia = ref.watch(currentMediaProvider);
    
    if (currentMedia == null) {
      return const SizedBox.shrink();
    }
    
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const PlayerScreen(),
          ),
        );
      },
      child: Container(
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
              minHeight: 2,
            ),
            
            // 播放信息
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // 缩略图/图标
                  Container(
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
                  
                  const SizedBox(width: 12),
                  
                  // 标题和时间
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          currentMedia.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${playbackState.positionString} / ${playbackState.durationString}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // 控制按钮
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 快退
                      IconButton(
                        icon: const Icon(Icons.replay_10),
                        iconSize: 24,
                        onPressed: () {
                          ref.read(playerProvider.notifier).skipBackward();
                        },
                      ),
                      
                      // 播放/暂停
                      IconButton(
                        icon: Icon(
                          playbackState.isPlaying
                              ? Icons.pause
                              : Icons.play_arrow,
                        ),
                        iconSize: 32,
                        onPressed: () {
                          ref.read(playerProvider.notifier).togglePlayPause();
                        },
                      ),
                      
                      // 快进
                      IconButton(
                        icon: const Icon(Icons.forward_10),
                        iconSize: 24,
                        onPressed: () {
                          ref.read(playerProvider.notifier).skipForward();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 媒体类型
enum MediaType {
  audio,
  video,
  unknown,
}
