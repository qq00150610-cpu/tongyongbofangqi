import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import '../models/app_settings.dart';

/// 设置页面
/// 
/// 包含所有应用设置选项
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      
      body: ListView(
        children: [
          // 播放设置分组
          _buildSectionHeader(context, '播放设置'),
          
          // 自动播放下一个
          SwitchListTile(
            title: const Text('自动播放下一个'),
            subtitle: const Text('播放完成后自动播放下一个'),
            value: settings.autoPlayNext,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).setAutoPlayNext(value);
            },
          ),
          
          // 记忆播放位置
          SwitchListTile(
            title: const Text('记忆播放位置'),
            subtitle: const Text('保存并恢复每个媒体的播放进度'),
            value: settings.rememberPosition,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).setRememberPosition(value);
            },
          ),
          
          // 定时关闭
          ListTile(
            title: const Text('定时关闭'),
            subtitle: Text(_getSleepTimerText(settings.sleepTimerMinutes)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showSleepTimerDialog(context, ref, settings),
          ),
          
          // 播放速度
          ListTile(
            title: const Text('默认播放速度'),
            subtitle: Text('${settings.defaultPlaybackSpeed}x'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showSpeedDialog(context, ref, settings),
          ),
          
          const Divider(),
          
          // 视频设置分组
          _buildSectionHeader(context, '视频设置'),
          
          // 播放品质
          ListTile(
            title: const Text('播放品质'),
            subtitle: Text(_getVideoQualityText(settings.videoQuality)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showQualityDialog(context, ref, settings),
          ),
          
          const Divider(),
          
          // 界面设置分组
          _buildSectionHeader(context, '界面设置'),
          
          // 主题模式
          ListTile(
            title: const Text('主题'),
            subtitle: Text(_getThemeText(settings.themeMode)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showThemeDialog(context, ref, settings),
          ),
          
          // 显示速度指示器
          SwitchListTile(
            title: const Text('显示播放速度'),
            subtitle: const Text('在播放器中显示当前播放速度'),
            value: settings.showSpeedIndicator,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).setShowSpeedIndicator(value);
            },
          ),
          
          const Divider(),
          
          // 手势设置分组
          _buildSectionHeader(context, '手势控制'),
          
          // 左侧手势功能
          SwitchListTile(
            title: const Text('左侧手势调节亮度'),
            subtitle: const Text('关闭后左侧手势将调节播放进度'),
            value: settings.leftSideControlsBrightness,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).setLeftSideControlsBrightness(value);
            },
          ),
          
          // 进度调节灵敏度
          ListTile(
            title: const Text('进度调节灵敏度'),
            subtitle: Text('${settings.seekSensitivity.toInt()} 秒'),
            trailing: SizedBox(
              width: 150,
              child: Slider(
                value: settings.seekSensitivity,
                min: 5,
                max: 30,
                divisions: 5,
                label: '${settings.seekSensitivity.toInt()}秒',
                onChanged: (value) {
                  ref.read(settingsProvider.notifier).setSeekSensitivity(value);
                },
              ),
            ),
          ),
          
          const Divider(),
          
          // 系统设置分组
          _buildSectionHeader(context, '系统'),
          
          // 锁屏控制
          SwitchListTile(
            title: const Text('锁屏播放控制'),
            subtitle: const Text('在锁屏界面显示播放控制'),
            value: settings.lockScreenControl,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).setLockScreenControl(value);
            },
          ),
          
          const Divider(),
          
          // 关于分组
          _buildSectionHeader(context, '关于'),
          
          // 版本信息
          const ListTile(
            title: Text('版本'),
            subtitle: Text('1.0.0'),
          ),
          
          // 许可证
          ListTile(
            title: const Text('开源许可证'),
            subtitle: const Text('MIT License'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLicenseDialog(context),
          ),
          
          // 重置设置
          ListTile(
            title: const Text('重置所有设置'),
            textColor: Colors.red,
            onTap: () => _showResetDialog(context, ref),
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// 构建分组标题
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// 获取定时关闭文本
  String _getSleepTimerText(int minutes) {
    if (minutes == 0) return '关闭';
    if (minutes < 60) return '$minutes 分钟';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) return '$hours 小时';
    return '$hours 小时 $mins 分钟';
  }

  /// 获取视频品质文本
  String _getVideoQualityText(int quality) {
    switch (quality) {
      case 0:
        return '自动';
      case 1:
        return '高 (1080p)';
      case 2:
        return '中 (720p)';
      case 3:
        return '低 (480p)';
      default:
        return '自动';
    }
  }

  /// 获取主题文本
  String _getThemeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return '跟随系统';
      case ThemeMode.light:
        return '浅色模式';
      case ThemeMode.dark:
        return '深色模式';
    }
  }

  /// 显示定时关闭对话框
  void _showSleepTimerDialog(BuildContext context, WidgetRef ref, AppSettings settings) {
    final options = [
      {'label': '关闭', 'value': 0},
      {'label': '15 分钟', 'value': 15},
      {'label': '30 分钟', 'value': 30},
      {'label': '45 分钟', 'value': 45},
      {'label': '60 分钟', 'value': 60},
      {'label': '90 分钟', 'value': 90},
      {'label': '120 分钟', 'value': 120},
    ];
    
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('定时关闭'),
        children: options.map((option) {
          final value = option['value'] as int;
          return RadioListTile<int>(
            title: Text(option['label'] as String),
            value: value,
            groupValue: settings.sleepTimerMinutes,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).setSleepTimer(value!);
              Navigator.pop(context);
            },
          );
        }).toList(),
      ),
    );
  }

  /// 显示播放速度对话框
  void _showSpeedDialog(BuildContext context, WidgetRef ref, AppSettings settings) {
    final options = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
    
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('默认播放速度'),
        children: options.map((speed) {
          return RadioListTile<double>(
            title: Text('${speed}x'),
            value: speed,
            groupValue: settings.defaultPlaybackSpeed,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).setDefaultPlaybackSpeed(value!);
              Navigator.pop(context);
            },
          );
        }).toList(),
      ),
    );
  }

  /// 显示画质选择对话框
  void _showQualityDialog(BuildContext context, WidgetRef ref, AppSettings settings) {
    final options = [
      {'label': '自动', 'value': 0},
      {'label': '高 (1080p)', 'value': 1},
      {'label': '中 (720p)', 'value': 2},
      {'label': '低 (480p)', 'value': 3},
    ];
    
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('播放品质'),
        children: options.map((option) {
          final value = option['value'] as int;
          return RadioListTile<int>(
            title: Text(option['label'] as String),
            value: value,
            groupValue: settings.videoQuality,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).setVideoQuality(value!);
              Navigator.pop(context);
            },
          );
        }).toList(),
      ),
    );
  }

  /// 显示主题选择对话框
  void _showThemeDialog(BuildContext context, WidgetRef ref, AppSettings settings) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('选择主题'),
        children: [
          RadioListTile<ThemeMode>(
            title: const Text('跟随系统'),
            value: ThemeMode.system,
            groupValue: settings.themeMode,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).setThemeMode(value!);
              Navigator.pop(context);
            },
          ),
          RadioListTile<ThemeMode>(
            title: const Text('浅色模式'),
            value: ThemeMode.light,
            groupValue: settings.themeMode,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).setThemeMode(value!);
              Navigator.pop(context);
            },
          ),
          RadioListTile<ThemeMode>(
            title: const Text('深色模式'),
            value: ThemeMode.dark,
            groupValue: settings.themeMode,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).setThemeMode(value!);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  /// 显示许可证对话框
  void _showLicenseDialog(BuildContext context) {
    showLicensePage(
      context: context,
      applicationName: '通用播放器',
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2024 Universal Player\n\nMIT License',
    );
  }

  /// 显示重置对话框
  void _showResetDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重置设置'),
        content: const Text('确定要重置所有设置为默认值吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              ref.read(settingsProvider.notifier).resetToDefault();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('设置已重置')),
              );
            },
            child: const Text('重置'),
          ),
        ],
      ),
    );
  }
}
