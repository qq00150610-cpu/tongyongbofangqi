import 'package:flutter/material.dart';

/// Duration扩展
extension DurationExtensions on Duration {
  /// 格式化为 HH:MM:SS
  String get formatted {
    final hours = inHours;
    final minutes = inMinutes % 60;
    final seconds = inSeconds % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
             '${minutes.toString().padLeft(2, '0')}:'
             '${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:'
           '${seconds.toString().padLeft(2, '0')}';
  }
  
  /// 格式化为 MM:SS
  String get shortFormatted {
    final minutes = inMinutes;
    final seconds = inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
           '${seconds.toString().padLeft(2, '0')}';
  }
  
  /// 获取进度百分比
  double progressOf(Duration total) {
    if (total.inMilliseconds == 0) return 0.0;
    return inMilliseconds / total.inMilliseconds;
  }
}

/// int扩展
extension IntExtensions on int {
  /// 转换为Duration
  Duration get milliseconds => Duration(milliseconds: this);
  Duration get seconds => Duration(seconds: this);
  Duration get minutes => Duration(minutes: this);
  Duration get hours => Duration(hours: this);
  
  /// 格式化文件大小
  String get fileSizeFormatted {
    if (this < 1024) {
      return '$this B';
    } else if (this < 1024 * 1024) {
      return '${(this / 1024).toStringAsFixed(1)} KB';
    } else if (this < 1024 * 1024 * 1024) {
      return '${(this / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(this / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }
}

/// String扩展
extension StringExtensions on String {
  /// 首字母大写
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
  
  /// 全小写
  String get lowercase => toLowerCase();
  
  /// 全大写
  String get uppercase => toUpperCase();
  
  /// 移除空格
  String get trimmed => trim();
  
  /// 是否为空或只有空格
  bool get isBlank => trim().isEmpty;
  
  /// 是否不为空
  bool get isNotBlank => !isBlank;
  
  /// 截断字符串
  String truncate(int maxLength, {String suffix = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}$suffix';
  }
}

/// DateTime扩展
extension DateTimeExtensions on DateTime {
  /// 格式化为日期字符串
  String get dateFormatted {
    return '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
  }
  
  /// 格式化为时间字符串
  String get timeFormatted {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
  
  /// 格式化为日期时间字符串
  String get dateTimeFormatted {
    return '$dateFormatted $timeFormatted';
  }
  
  /// 获取相对时间字符串
  String get relativeTime {
    final now = DateTime.now();
    final difference = now.difference(this);
    
    if (difference.inSeconds < 60) {
      return '刚刚';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}小时前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}周前';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()}月前';
    } else {
      return '${(difference.inDays / 365).floor()}年前';
    }
  }
}

/// List扩展
extension ListExtensions<T> on List<T> {
  /// 安全获取元素
  T? safeGet(int index) {
    if (index >= 0 && index < length) {
      return this[index];
    }
    return null;
  }
  
  /// 交换元素
  void swap(int index1, int index2) {
    if (index1 >= 0 && index1 < length && 
        index2 >= 0 && index2 < length) {
      final temp = this[index1];
      this[index1] = this[index2];
      this[index2] = temp;
    }
  }
}

/// Context扩展
extension ContextExtensions on BuildContext {
  /// 获取主题
  ThemeData get theme => Theme.of(this);
  
  /// 获取文本主题
  TextTheme get textTheme => Theme.of(this).textTheme;
  
  /// 获取颜色主题
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  
  /// 获取媒体查询数据
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  
  /// 获取屏幕大小
  Size get screenSize => MediaQuery.of(this).size;
  
  /// 获取屏幕宽度
  double get screenWidth => MediaQuery.of(this).size.width;
  
  /// 获取屏幕高度
  double get screenHeight => MediaQuery.of(this).size.height;
  
  /// 获取底部安全区高度
  double get bottomPadding => MediaQuery.of(this).padding.bottom;
  
  /// 获取顶部安全区高度
  double get topPadding => MediaQuery.of(this).padding.top;
  
  /// 是否是深色模式
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
  
  /// 显示SnackBar
  void showSnackBar(String message, {Duration? duration}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration ?? const Duration(seconds: 2),
      ),
    );
  }
}

/// Color扩展
extension ColorExtensions on Color {
  /// 获取对比色（黑或白）
  Color get contrastColor {
    final luminance = computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}

/// Double扩展
extension DoubleExtensions on double {
  /// 限制在范围内
  double clamp(double min, double max) {
    if (this < min) return min;
    if (this > max) return max;
    return this;
  }
  
  /// 转换为百分比字符串
  String toPercentString({int decimals = 0}) {
    return '${(this * 100).toStringAsFixed(decimals)}%';
  }
}
