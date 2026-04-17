import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_settings.dart';
import '../services/storage_service.dart';

/// 设置Provider
/// 
/// 管理应用的所有设置：
/// - 主题模式
/// - 播放设置
/// - 定时关闭
/// - 画质设置
class SettingsNotifier extends StateNotifier<AppSettings> {
  final StorageService _storageService;
  
  SettingsNotifier(this._storageService) : super(AppSettings.defaultSettings) {
    _init();
  }
  
  /// 初始化
  Future<void> _init() async {
    final settings = await _storageService.loadSettings();
    state = settings;
  }
  
  /// 保存设置
  Future<void> _saveSettings() async {
    await _storageService.saveSettings(state);
  }
  
  /// 设置主题模式
  Future<void> setThemeMode(themeMode) async {
    state = state.copyWith(themeMode: themeMode);
    await _saveSettings();
  }
  
  /// 设置自动播放下一个
  Future<void> setAutoPlayNext(bool value) async {
    state = state.copyWith(autoPlayNext: value);
    await _saveSettings();
  }
  
  /// 设置记忆播放位置
  Future<void> setRememberPosition(bool value) async {
    state = state.copyWith(rememberPosition: value);
    await _saveSettings();
  }
  
  /// 设置定时关闭时间（分钟）
  Future<void> setSleepTimer(int minutes) async {
    state = state.copyWith(sleepTimerMinutes: minutes);
    await _saveSettings();
  }
  
  /// 设置默认播放速度
  Future<void> setDefaultPlaybackSpeed(double speed) async {
    state = state.copyWith(defaultPlaybackSpeed: speed);
    await _saveSettings();
  }
  
  /// 设置播放品质
  Future<void> setVideoQuality(int quality) async {
    state = state.copyWith(videoQuality: quality);
    await _saveSettings();
  }
  
  /// 设置显示速度指示器
  Future<void> setShowSpeedIndicator(bool value) async {
    state = state.copyWith(showSpeedIndicator: value);
    await _saveSettings();
  }
  
  /// 设置滑动调节灵敏度
  Future<void> setSeekSensitivity(double value) async {
    state = state.copyWith(seekSensitivity: value);
    await _saveSettings();
  }
  
  /// 设置音量灵敏度
  Future<void> setVolumeSensitivity(double value) async {
    state = state.copyWith(volumeSensitivity: value);
    await _saveSettings();
  }
  
  /// 设置亮度灵敏度
  Future<void> setBrightnessSensitivity(double value) async {
    state = state.copyWith(brightnessSensitivity: value);
    await _saveSettings();
  }
  
  /// 设置左侧手势控制类型
  Future<void> setLeftSideControlsBrightness(bool value) async {
    state = state.copyWith(leftSideControlsBrightness: value);
    await _saveSettings();
  }
  
  /// 设置锁屏控制
  Future<void> setLockScreenControl(bool value) async {
    state = state.copyWith(lockScreenControl: value);
    await _saveSettings();
  }
  
  /// 设置WiFi下加载缩略图
  Future<void> setWifiOnlyThumbnails(bool value) async {
    state = state.copyWith(wifiOnlyThumbnails: value);
    await _saveSettings();
  }
  
  /// 重置为默认设置
  Future<void> resetToDefault() async {
    state = AppSettings.defaultSettings;
    await _saveSettings();
  }
  
  /// 应用设置
  AppSettings get settings => state;
}

/// 设置Provider
final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier(StorageService.instance);
});

/// 主题模式Provider
final themeModeProvider = Provider(themeModeSelector);

dynamic themeModeSelector(Ref ref) {
  return ref.watch(settingsProvider).themeMode;
}

/// 自动播放下一个Provider
final autoPlayNextProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider).autoPlayNext;
});

/// 记忆播放位置Provider
final rememberPositionProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider).rememberPosition;
});

/// 定时关闭时间Provider
final sleepTimerProvider = Provider<int>((ref) {
  return ref.watch(settingsProvider).sleepTimerMinutes;
});

/// 播放速度Provider
final playbackSpeedProvider = Provider<double>((ref) {
  return ref.watch(settingsProvider).defaultPlaybackSpeed;
});
