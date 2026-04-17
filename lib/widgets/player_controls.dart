import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/player_provider.dart';
import '../providers/playlist_provider.dart';
import '../providers/settings_provider.dart';
import '../models/playback_state.dart';

/// 播放控制组件
/// 
/// 包含播放、暂停、快进、快退等控制按钮
class PlayerControls extends ConsumerWidget {
  /// 是否显示播放列表按钮
  final bool showPlaylistButton;
  
  /// 是否显示倍速按钮
  final bool showSpeedButton;

  const PlayerControls({
    super.key,
    this.showPlaylistButton = true,
    this.showSpeedButton = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playbackState = ref.watch(playerProvider);
    final playlistState = ref.watch(playlistProvider);
    final settings = ref.watch(settingsProvider);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 倍速指示器
        if (settings.showSpeedIndicator && playbackState.speed != 1.0)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${playbackState.speed}x',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        
        // 主控制按钮
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 播放列表按钮
            if (showPlaylistButton)
              IconButton(
                icon: const Icon(Icons.queue_music),
                iconSize: 28,
                onPressed: () {
                  // TODO: 打开播放列表
                },
              ),
            
            // 上一首
            IconButton(
              icon: const Icon(Icons.skip_previous),
              iconSize: 36,
              onPressed: playlistState.hasPrevious
                  ? () => ref.read(playlistProvider.notifier).playPrevious()
                  : null,
            ),
            
            // 快退
            IconButton(
              icon: const Icon(Icons.replay_10),
              iconSize: 36,
              onPressed: () {
                ref.read(playerProvider.notifier).skipBackward(
                  seconds: settings.seekSensitivity,
                );
              },
            ),
            
            const SizedBox(width: 8),
            
            // 播放/暂停按钮
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(
                  playbackState.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                ),
                iconSize: 48,
                padding: const EdgeInsets.all(12),
                onPressed: () {
                  ref.read(playerProvider.notifier).togglePlayPause();
                },
              ),
            ),
            
            const SizedBox(width: 8),
            
            // 快进
            IconButton(
              icon: const Icon(Icons.forward_10),
              iconSize: 36,
              onPressed: () {
                ref.read(playerProvider.notifier).skipForward(
                  seconds: settings.seekSensitivity,
                );
              },
            ),
            
            // 下一首
            IconButton(
              icon: const Icon(Icons.skip_next),
              iconSize: 36,
              onPressed: playlistState.hasNext
                  ? () => ref.read(playlistProvider.notifier).playNext()
                  : null,
            ),
            
            // 倍速按钮
            if (showSpeedButton)
              IconButton(
                icon: const Icon(Icons.speed),
                iconSize: 28,
                onPressed: () => _showSpeedPicker(context, ref, playbackState),
              ),
          ],
        ),
        
        // 缓冲指示
        if (playbackState.isBuffering)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
      ],
    );
  }

  /// 显示倍速选择器
  void _showSpeedPicker(
    BuildContext context,
    WidgetRef ref,
    PlaybackState state,
  ) {
    final speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
    
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  '播放速度',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...speeds.map((speed) {
                final isSelected = state.speed == speed;
                return ListTile(
                  title: Text(
                    '${speed}x',
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : null,
                      color: isSelected ? Theme.of(context).primaryColor : null,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(
                          Icons.check,
                          color: Theme.of(context).primaryColor,
                        )
                      : null,
                  onTap: () {
                    ref.read(playerProvider.notifier).setSpeed(speed);
                    Navigator.pop(context);
                  },
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

/// 播放模式切换按钮
class PlaybackModeButton extends ConsumerWidget {
  const PlaybackModeButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playbackMode = ref.watch(playbackModeProvider);
    
    return IconButton(
      icon: Text(
        playbackMode.icon,
        style: const TextStyle(fontSize: 24),
      ),
      tooltip: playbackMode.displayName,
      onPressed: () {
        ref.read(playlistProvider.notifier).togglePlaybackMode();
        
        // 显示当前模式
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ref.read(playlistProvider).playbackMode.displayName),
            duration: const Duration(seconds: 1),
          ),
        );
      },
    );
  }
}

/// 音量控制组件
class VolumeControl extends ConsumerWidget {
  const VolumeControl({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playbackState = ref.watch(playerProvider);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          playbackState.volume == 0
              ? Icons.volume_off
              : playbackState.volume < 0.5
                  ? Icons.volume_down
                  : Icons.volume_up,
          size: 20,
        ),
        SizedBox(
          width: 100,
          child: Slider(
            value: playbackState.volume,
            onChanged: (value) {
              ref.read(playerProvider.notifier).setVolume(value);
            },
          ),
        ),
      ],
    );
  }
}
