# Universal Player Flutter项目

这是一个基于Flutter开发的全平台通用音视频播放器应用。

## 功能特性

- ✅ 支持所有主流音视频格式（MP3/MP4/FLAC/AVI/MKV/MOV等）
- ✅ 跨平台支持（Android/iOS/鸿蒙）
- ✅ 锁屏播放控制
- ✅ 快进快退控制
- ✅ 自动播放下一个
- ✅ 手势操作（滑动调节进度/音量/亮度）
- ✅ 播放列表管理
- ✅ 记忆播放位置
- ✅ 完全免费无广告

## 项目结构

```
universal_player/
├── lib/
│   ├── main.dart              # 应用入口
│   ├── models/                # 数据模型
│   ├── providers/             # 状态管理
│   ├── screens/               # 页面
│   ├── services/              # 服务层
│   ├── widgets/               # UI组件
│   └── utils/                 # 工具类
├── android/                   # Android配置
├── ios/                      # iOS配置
└── pubspec.yaml             # 项目配置
```

## 开始使用

### 1. 环境要求

- Flutter SDK ≥ 3.0.0
- Dart SDK ≥ 2.18.0
- Android Studio (Android开发)
- Xcode (iOS开发)

### 2. 安装依赖

```bash
cd universal_player
flutter pub get
```

### 3. 运行调试

```bash
# Android
flutter run -d android

# iOS (macOS)
flutter run -d ios
```

### 4. 构建发布

```bash
# Android APK
flutter build apk --release

# Android AAB
flutter build appbundle --release

# iOS
flutter build ios --release
```

## 技术栈

- **框架**: Flutter 3.0+
- **状态管理**: Riverpod
- **音视频引擎**: media_kit
- **后台播放**: audio_service

## 许可证

MIT License
