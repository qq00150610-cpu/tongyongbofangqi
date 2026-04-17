import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../providers/player_provider.dart';
import '../providers/playlist_provider.dart';
import '../providers/settings_provider.dart';
import '../services/player_service.dart';
import '../models/playback_state.dart';
import '../widgets/player_controls.dart';
import '../widgets/progress_bar.dart';
import '../widgets/gesture_overlay.dart';
import 'playlist_screen.dart';

/// 播放器页面
/// 
/// 全屏播放器界面，支持：
/// - 视频播放
/// - 播放控制
/// - 手势操作
/// - 全屏模式
class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key});

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen>
    with SingleTickerProviderStateMixin {
  late final VideoController _videoController;
  late final AnimationController _controlsAnimationController;
  
  bool _showControls = true;
  bool _isFullScreen = false;
  double _brightness = 0.5;
  double _volume = 1.0;
  
  @override
  void initState() {
    super.initState();
    
    // 获取视频控制器
    _videoController = PlayerService.instance.videoController;
    
    // 创建控制动画控制器
    _controlsAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _controlsAnimationController.forward();
    
    // 启用屏幕常亮
    WakelockPlus.enable();
    
    // 隐藏状态栏
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
    );
    
    // 监听完成事件以自动播放下一个
    _setupCompletedListener();
  }

  @override
  void dispose() {
    _controlsAnimationController.dispose();
    
    // 禁用屏幕常亮
    WakelockPlus.disable();
    
    // 恢复系统UI
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
    );
    
    // 退出全屏
    if (_isFullScreen) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    }
    
    super.dispose();
  }

  /// 设置播放完成监听
  void _setupCompletedListener() {
    final settings = ref.read(settingsProvider);
    
    PlayerService.instance.addCompletedListener(() {
      if (settings.autoPlayNext) {
        ref.read(playlistProvider.notifier).playNext();
      }
    });
  }

  /// 切换控制栏显示
  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    
    if (_showControls) {
      _controlsAnimationController.forward();
    } else {
      _controlsAnimationController.reverse();
    }
  }

  /// 切换全屏
  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });
    
    if (_isFullScreen) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.edgeToEdge,
      );
    }
  }

  /// 播放/暂停
  void _togglePlayPause() {
    ref.read(playerProvider.notifier).togglePlayPause();
  }

  /// 快进
  void _skipForward() {
    final settings = ref.read(settingsProvider);
    ref.read(playerProvider.notifier).skipForward(
      seconds: settings.seekSensitivity,
    );
  }

  /// 快退
  void _skipBackward() {
    final settings = ref.read(settingsProvider);
    ref.read(playerProvider.notifier).skipBackward(
      seconds: settings.seekSensitivity,
    );
  }

  /// 跳转到指定位置
  void _seekTo(Duration position) {
    ref.read(playerProvider.notifier).seekTo(position);
  }

  /// 打开播放列表
  void _openPlaylist() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PlaylistScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final playbackState = ref.watch(playerProvider);
    final currentMedia = ref.watch(currentMediaProvider);
    final settings = ref.watch(settingsProvider);
    
    // 判断是否为音频
    final isAudio = currentMedia?.type == MediaType.audio;
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // 视频/音频可视化区域
            if (isAudio)
              _buildAudioVisualization(playbackState)
            else
              _buildVideoPlayer(),
            
            // 手势操作层
            GestureOverlay(
              onTap: _toggleControls,
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity != null) {
                  if (details.primaryVelocity! > 0) {
                    _skipForward();
                  } else if (details.primaryVelocity! < 0) {
                    _skipBackward();
                  }
                }
              },
              onVolumeChange: (delta) {
                setState(() {
                  _volume = (_volume + delta).clamp(0.0, 1.0);
                });
                ref.read(playerProvider.notifier).setVolume(_volume);
              },
              onBrightnessChange: (delta) {
                setState(() {
                  _brightness = (_brightness + delta).clamp(0.0, 1.0);
                });
                // 设置屏幕亮度
                BrightnessController.instance.set(_brightness);
              },
              leftSideControlsBrightness: settings.leftSideControlsBrightness,
            ),
            
            // 控制栏
            if (_showControls)
              _buildControlsOverlay(playbackState, currentMedia, settings),
            
            // 音量/亮度指示器
            if (_showControls)
              _buildIndicators(),
          ],
        ),
      ),
    );
  }

  /// 构建视频播放器
  Widget _buildVideoPlayer() {
    return Center(
      child: Video(
        controller: _videoController,
        fit: BoxFit.contain,
      ),
    );
  }

  /// 构建音频可视化
  Widget _buildAudioVisualization(PlaybackState state) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.3),
            Colors.black,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 音乐图标
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.music_note,
                size: 80,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            // 波形动画
            SizedBox(
              height: 60,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(7, (index) {
                  return AnimatedContainer(
                    duration: Duration(milliseconds: 200 + index * 50),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: 8,
                    height: state.isPlaying ? 20 + (index % 3) * 15.0 : 20,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建控制栏覆盖层
  Widget _buildControlsOverlay(
    PlaybackState state,
    MediaItem? media,
    settings,
  ) {
    return FadeTransition(
      opacity: _controlsAnimationController,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black54,
              Colors.transparent,
              Colors.transparent,
              Colors.black54,
            ],
            stops: const [0.0, 0.2, 0.8, 1.0],
          ),
        ),
        child: Column(
          children: [
            // 顶部栏
            _buildTopBar(media),
            
            // 中间区域
            Expanded(
              child: Center(
                child: _buildCenterControls(state, settings),
              ),
            ),
            
            // 底部栏
            _buildBottomBar(state),
          ],
        ),
      ),
    );
  }

  /// 构建顶部栏
  Widget _buildTopBar(MediaItem? media) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          // 返回按钮
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          
          // 标题
          Expanded(
            child: Text(
              media?.name ?? '未知',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          // 播放列表按钮
          IconButton(
            icon: const Icon(Icons.queue_music, color: Colors.white),
            onPressed: _openPlaylist,
          ),
        ],
      ),
    );
  }

  /// 构建中央控制按钮
  Widget _buildCenterControls(PlaybackState state, settings) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 快退按钮
        IconButton(
          icon: const Icon(Icons.replay_10, size: 48, color: Colors.white),
          onPressed: _skipBackward,
        ),
        
        const SizedBox(width: 24),
        
        // 播放/暂停按钮
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              state.isPlaying ? Icons.pause : Icons.play_arrow,
              size: 48,
              color: Colors.white,
            ),
            onPressed: _togglePlayPause,
          ),
        ),
        
        const SizedBox(width: 24),
        
        // 快进按钮
        IconButton(
          icon: const Icon(Icons.forward_10, size: 48, color: Colors.white),
          onPressed: _skipForward,
        ),
      ],
    );
  }

  /// 构建底部栏
  Widget _buildBottomBar(PlaybackState state) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 进度条
          ProgressBar(
            position: state.position,
            duration: state.duration,
            onSeek: _seekTo,
          ),
          
          const SizedBox(height: 8),
          
          // 时间和控制按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 当前时间
              Text(
                state.positionString,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              
              // 时间指示
              Text(
                '${state.positionString} / ${state.durationString}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              
              // 总时长
              Text(
                state.durationString,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建指示器
  Widget _buildIndicators() {
    return Stack(
      children: [
        // 音量指示器
        Positioned(
          left: 40,
          top: 0,
          bottom: 0,
          child: Center(
            child: AnimatedOpacity(
              opacity: _volume != 1.0 ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _volume == 0 ? Icons.volume_off : Icons.volume_up,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 100,
                      child: RotatedBox(
                        quarterTurns: -1,
                        child: LinearProgressIndicator(
                          value: _volume,
                          backgroundColor: Colors.white30,
                          valueColor: const AlwaysStoppedAnimation(Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(_volume * 100).toInt()}%',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        
        // 亮度指示器
        Positioned(
          right: 40,
          top: 0,
          bottom: 0,
          child: Center(
            child: AnimatedOpacity(
              opacity: _brightness != 0.5 ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.brightness_high,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 100,
                      child: RotatedBox(
                        quarterTurns: -1,
                        child: LinearProgressIndicator(
                          value: _brightness,
                          backgroundColor: Colors.white30,
                          valueColor: const AlwaysStoppedAnimation(Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(_brightness * 100).toInt()}%',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 亮度控制器（简化版）
class BrightnessController {
  static final BrightnessController instance = BrightnessController._internal();
  factory BrightnessController() => instance;
  BrightnessController._internal();
  
  double _brightness = 0.5;
  
  void set(double brightness) {
    _brightness = brightness.clamp(0.0, 1.0);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }
  
  double get brightness => _brightness;
}
