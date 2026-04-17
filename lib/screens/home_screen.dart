import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/player_provider.dart';
import '../providers/playlist_provider.dart';
import '../models/playback_state.dart';
import 'file_browser_screen.dart';
import 'playlist_screen.dart';
import 'settings_screen.dart';
import '../widgets/mini_player.dart';

/// 主页
/// 
/// 应用的主页面，包含底部导航栏：
/// - 文件浏览
/// - 播放列表
/// - 设置
/// 以及底部迷你播放器
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = const [
    FileBrowserScreen(),
    PlaylistScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final playbackState = ref.watch(playerProvider);
    final hasMedia = playbackState.status != PlaybackStatus.idle;
    
    return Scaffold(
      // 页面内容
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      
      // 底部导航栏
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 迷你播放器
          if (hasMedia)
            const MiniPlayer(),
          
          // 导航栏
          NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.folder_outlined),
                selectedIcon: Icon(Icons.folder),
                label: '文件',
              ),
              NavigationDestination(
                icon: Icon(Icons.queue_music_outlined),
                selectedIcon: Icon(Icons.queue_music),
                label: '播放列表',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: '设置',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
