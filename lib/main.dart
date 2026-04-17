import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';

import 'screens/home_screen.dart';
import 'services/player_service.dart';
import 'services/storage_service.dart';
import 'providers/settings_provider.dart';

void main() async {
  // 确保Flutter绑定初始化完成
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化媒体播放套件 - 必须在使用任何media_kit功能前调用
  MediaKit.ensureInitialized();
  
  // 初始化存储服务
  await StorageService.instance.init();
  
  // 初始化播放器服务
  await PlayerService.instance.init();
  
  // 运行应用
  runApp(
    // 使用ProviderScope包裹整个应用，以支持Riverpod状态管理
    const ProviderScope(
      child: UniversalPlayerApp(),
    ),
  );
}

/// 通用音视频播放器应用主组件
class UniversalPlayerApp extends ConsumerWidget {
  const UniversalPlayerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 获取主题设置
    final settings = ref.watch(settingsProvider);
    
    return MaterialApp(
      // 应用标题
      title: '通用播放器',
      
      // 调试标签
      debugShowCheckedModeBanner: false,
      
      // 主题配置
      theme: ThemeData(
        // 使用紫色作为主色调，符合媒体应用的风格
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        // 使用Material 3设计
        useMaterial3: true,
      ),
      
      // 深色主题配置
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      
      // 根据设置决定使用哪个主题
      themeMode: settings.themeMode,
      
      // 应用主页
      home: const HomeScreen(),
    );
  }
}
