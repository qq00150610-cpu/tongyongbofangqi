import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings.dart';
import '../models/media_item.dart';

/// 本地存储服务
/// 
/// 使用SharedPreferences存储应用数据：
/// - 应用设置
/// - 播放历史
/// - 播放列表
/// - 播放位置
class StorageService {
  // 单例模式
  static final StorageService instance = StorageService._internal();
  factory StorageService() => instance;
  StorageService._internal();
  
  /// SharedPreferences实例
  SharedPreferences? _prefs;
  
  /// 存储键名
  static const String _settingsKey = 'app_settings';
  static const String _playlistKey = 'playlist';
  static const String _historyKey = 'play_history';
  static const String _positionPrefix = 'position_';
  
  /// 是否已初始化
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  
  /// 初始化存储服务
  Future<void> init() async {
    if (_isInitialized) return;
    
    try {
      _prefs = await SharedPreferences.getInstance();
      _isInitialized = true;
      debugPrint('StorageService initialized');
    } catch (e) {
      debugPrint('Failed to initialize StorageService: $e');
      rethrow;
    }
  }
  
  /// 确保已初始化
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await init();
    }
  }
  
  // ==================== 应用设置 ====================
  
  /// 保存应用设置
  Future<void> saveSettings(AppSettings settings) async {
    await _ensureInitialized();
    try {
      final json = jsonEncode(settings.toJson());
      await _prefs!.setString(_settingsKey, json);
      debugPrint('Settings saved');
    } catch (e) {
      debugPrint('Failed to save settings: $e');
    }
  }
  
  /// 加载应用设置
  Future<AppSettings> loadSettings() async {
    await _ensureInitialized();
    try {
      final json = _prefs!.getString(_settingsKey);
      if (json != null) {
        final map = jsonDecode(json) as Map<String, dynamic>;
        return AppSettings.fromJson(map);
      }
    } catch (e) {
      debugPrint('Failed to load settings: $e');
    }
    return AppSettings.defaultSettings;
  }
  
  // ==================== 播放列表 ====================
  
  /// 保存播放列表
  Future<void> savePlaylist(List<MediaItem> playlist) async {
    await _ensureInitialized();
    try {
      final jsonList = playlist.map((item) => item.toJson()).toList();
      final json = jsonEncode(jsonList);
      await _prefs!.setString(_playlistKey, json);
      debugPrint('Playlist saved (${playlist.length} items)');
    } catch (e) {
      debugPrint('Failed to save playlist: $e');
    }
  }
  
  /// 加载播放列表
  Future<List<MediaItem>> loadPlaylist() async {
    await _ensureInitialized();
    try {
      final json = _prefs!.getString(_playlistKey);
      if (json != null) {
        final jsonList = jsonDecode(json) as List;
        return jsonList
            .map((item) => MediaItem.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('Failed to load playlist: $e');
    }
    return [];
  }
  
  /// 清空播放列表
  Future<void> clearPlaylist() async {
    await _ensureInitialized();
    await _prefs!.remove(_playlistKey);
    debugPrint('Playlist cleared');
  }
  
  // ==================== 播放历史 ====================
  
  /// 添加到播放历史
  Future<void> addToHistory(MediaItem media) async {
    await _ensureInitialized();
    try {
      final history = await loadHistory();
      
      // 移除已存在的相同项
      history.removeWhere((item) => item.id == media.id);
      
      // 添加到列表开头
      history.insert(0, media.copyWith(
        lastPlayed: DateTime.now(),
      ));
      
      // 最多保存100条历史
      if (history.length > 100) {
        history.removeRange(100, history.length);
      }
      
      // 保存历史
      final jsonList = history.map((item) => item.toJson()).toList();
      await _prefs!.setString(_historyKey, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Failed to add to history: $e');
    }
  }
  
  /// 加载播放历史
  Future<List<MediaItem>> loadHistory() async {
    await _ensureInitialized();
    try {
      final json = _prefs!.getString(_historyKey);
      if (json != null) {
        final jsonList = jsonDecode(json) as List;
        return jsonList
            .map((item) => MediaItem.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('Failed to load history: $e');
    }
    return [];
  }
  
  /// 清空播放历史
  Future<void> clearHistory() async {
    await _ensureInitialized();
    await _prefs!.remove(_historyKey);
    debugPrint('History cleared');
  }
  
  // ==================== 播放位置 ====================
  
  /// 保存播放位置
  Future<void> savePosition(String mediaId, Duration position) async {
    await _ensureInitialized();
    try {
      await _prefs!.setInt('$_positionPrefix$mediaId', position.inSeconds);
    } catch (e) {
      debugPrint('Failed to save position: $e');
    }
  }
  
  /// 加载播放位置
  Future<Duration?> loadPosition(String mediaId) async {
    await _ensureInitialized();
    try {
      final seconds = _prefs!.getInt('$_positionPrefix$mediaId');
      if (seconds != null) {
        return Duration(seconds: seconds);
      }
    } catch (e) {
      debugPrint('Failed to load position: $e');
    }
    return null;
  }
  
  /// 删除播放位置
  Future<void> deletePosition(String mediaId) async {
    await _ensureInitialized();
    await _prefs!.remove('$_positionPrefix$mediaId');
  }
  
  /// 清空所有播放位置
  Future<void> clearAllPositions() async {
    await _ensureInitialized();
    final keys = _prefs!.getKeys().where((key) => key.startsWith(_positionPrefix));
    for (final key in keys) {
      await _prefs!.remove(key);
    }
    debugPrint('All positions cleared');
  }
  
  // ==================== 其他 ====================
  
  /// 保存数据
  Future<void> save(String key, dynamic value) async {
    await _ensureInitialized();
    try {
      if (value is String) {
        await _prefs!.setString(key, value);
      } else if (value is int) {
        await _prefs!.setInt(key, value);
      } else if (value is double) {
        await _prefs!.setDouble(key, value);
      } else if (value is bool) {
        await _prefs!.setBool(key, value);
      } else {
        await _prefs!.setString(key, jsonEncode(value));
      }
    } catch (e) {
      debugPrint('Failed to save: $e');
    }
  }
  
  /// 加载数据
  Future<T?> load<T>(String key) async {
    await _ensureInitialized();
    try {
      return _prefs!.get(key) as T?;
    } catch (e) {
      debugPrint('Failed to load: $e');
      return null;
    }
  }
  
  /// 删除数据
  Future<void> delete(String key) async {
    await _ensureInitialized();
    await _prefs!.remove(key);
  }
  
  /// 清空所有数据
  Future<void> clearAll() async {
    await _ensureInitialized();
    await _prefs!.clear();
    debugPrint('All data cleared');
  }
}
