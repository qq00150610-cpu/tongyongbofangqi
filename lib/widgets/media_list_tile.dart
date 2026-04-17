import 'package:flutter/material.dart';
import '../models/media_item.dart';

/// 媒体列表项组件
/// 
/// 用于在文件列表和播放列表中显示单个媒体项
class MediaListTile extends StatelessWidget {
  /// 媒体项
  final MediaItem media;
  
  /// 是否正在播放
  final bool isPlaying;
  
  /// 是否显示时长
  final bool showDuration;
  
  /// 点击回调
  final VoidCallback? onTap;
  
  /// 长按回调
  final VoidCallback? onLongPress;
  
  /// 尾部组件
  final Widget? trailing;
  
  /// 副标题
  final String? subtitle;

  const MediaListTile({
    super.key,
    required this.media,
    this.isPlaying = false,
    this.showDuration = false,
    this.onTap,
    this.onLongPress,
    this.trailing,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      // 左侧图标
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isPlaying
              ? Theme.of(context).primaryColor
              : Theme.of(context).primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: isPlaying
              ? const Icon(Icons.equalizer, color: Colors.white)
              : Icon(
                  _getMediaIcon(),
                  color: Theme.of(context).primaryColor,
                ),
        ),
      ),
      
      // 标题
      title: Text(
        media.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
          color: isPlaying ? Theme.of(context).primaryColor : null,
        ),
      ),
      
      // 副标题
      subtitle: Text(
        subtitle ?? _getSubtitle(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).textTheme.bodySmall?.color,
        ),
      ),
      
      // 尾部
      trailing: trailing,
      
      // 点击事件
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }

  /// 获取媒体图标
  IconData _getMediaIcon() {
    switch (media.type) {
      case MediaType.audio:
        return Icons.music_note;
      case MediaType.video:
        return Icons.videocam;
      case MediaType.unknown:
        return Icons.insert_drive_file;
    }
  }

  /// 获取副标题文本
  String _getSubtitle() {
    final parts = <String>[];
    
    // 文件类型
    parts.add(media.extension.toUpperCase());
    
    // 文件大小
    if (media.size > 0) {
      parts.add(_formatFileSize(media.size));
    }
    
    // 时长
    if (showDuration && media.duration != null) {
      parts.add(_formatDuration(media.duration!));
    }
    
    return parts.join(' · ');
  }

  /// 格式化文件大小
  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }

  /// 格式化时长
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
