import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/file_provider.dart';
import '../providers/playlist_provider.dart';
import '../models/media_item.dart';
import '../services/file_service.dart';
import '../widgets/media_list_tile.dart';
import 'player_screen.dart';

/// 文件浏览器页面
/// 
/// 用于浏览和选择本地媒体文件
class FileBrowserScreen extends ConsumerStatefulWidget {
  const FileBrowserScreen({super.key});

  @override
  ConsumerState<FileBrowserScreen> createState() => _FileBrowserScreenState();
}

class _FileBrowserScreenState extends ConsumerState<FileBrowserScreen> {
  bool _hasPermission = false;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 检查存储权限
  Future<void> _checkPermission() async {
    // 根据平台检查权限
    if (Theme.of(context).platform == TargetPlatform.android) {
      // Android需要检查存储权限
      // Android 13+ 使用 READ_MEDIA_AUDIO 和 READ_MEDIA_VIDEO
      // Android 12及以下使用 READ_EXTERNAL_STORAGE
      
      // 先尝试媒体权限
      var status = await Permission.audio.request();
      if (status.isGranted) {
        status = await Permission.videos.request();
      }
      
      if (status.isGranted) {
        setState(() => _hasPermission = true);
        // 加载文件
        ref.read(fileBrowserProvider.notifier).refresh();
        return;
      }
      
      // 如果媒体权限失败，尝试存储权限（Android 12及以下）
      status = await Permission.storage.request();
      if (status.isGranted) {
        setState(() => _hasPermission = true);
        ref.read(fileBrowserProvider.notifier).refresh();
        return;
      }
      
      setState(() => _hasPermission = false);
    } else {
      // iOS和其他平台通常不需要运行时权限
      setState(() => _hasPermission = true);
      ref.read(fileBrowserProvider.notifier).refresh();
    }
  }

  /// 请求权限
  Future<void> _requestPermission() async {
    // 打开应用设置页面
    await openAppSettings();
  }

  /// 选择文件
  Future<void> _pickFiles() async {
    final mediaFiles = await FileService.instance.pickMediaFiles();
    if (mediaFiles != null && mediaFiles.isNotEmpty) {
      ref.read(playlistProvider.notifier).addAllToPlaylist(mediaFiles);
      
      // 显示提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已添加 ${mediaFiles.length} 个文件到播放列表'),
            action: SnackBarAction(
              label: '查看',
              onPressed: () {
                // 切换到播放列表
                DefaultTabController.of(context).animateTo(1);
              },
            ),
          ),
        );
      }
    }
  }

  /// 播放媒体
  void _playMedia(MediaItem media) {
    ref.read(playlistProvider.notifier).playMedia(media);
    
    // 如果是视频或用户选择全屏播放，打开播放器页面
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PlayerScreen(),
      ),
    );
  }

  /// 显示排序选项
  void _showSortOptions() {
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
                  '排序方式',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...FileSortBy.values.map((sortBy) {
                final currentSort = ref.read(fileBrowserProvider).sortBy;
                final isSelected = currentSort == sortBy;
                
                return ListTile(
                  leading: Icon(
                    _getSortIcon(sortBy),
                    color: isSelected ? Theme.of(context).primaryColor : null,
                  ),
                  title: Text(sortBy.displayName),
                  trailing: isSelected
                      ? Icon(
                          ref.read(fileBrowserProvider).sortAscending
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          color: Theme.of(context).primaryColor,
                        )
                      : null,
                  onTap: () {
                    ref.read(fileBrowserProvider.notifier).sortBy(sortBy);
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

  /// 获取排序图标
  IconData _getSortIcon(FileSortBy sortBy) {
    switch (sortBy) {
      case FileSortBy.name:
        return Icons.sort_by_alpha;
      case FileSortBy.size:
        return Icons.data_usage;
      case FileSortBy.date:
        return Icons.calendar_today;
      case FileSortBy.type:
        return Icons.category;
    }
  }

  /// 切换搜索
  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        ref.read(fileBrowserProvider.notifier).clearSearch();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final browserState = ref.watch(fileBrowserProvider);
    final files = ref.watch(fileBrowserProvider.notifier).displayFiles;
    
    return Scaffold(
      // 标题栏
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: '搜索文件...',
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  ref.read(fileBrowserProvider.notifier).search(value);
                },
              )
            : const Text('文件浏览'),
        actions: [
          // 搜索按钮
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: _toggleSearch,
          ),
          // 排序按钮
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: _showSortOptions,
          ),
          // 选择文件夹
          IconButton(
            icon: const Icon(Icons.folder_open),
            onPressed: () {
              ref.read(fileBrowserProvider.notifier).pickDirectory();
            },
          ),
        ],
      ),
      
      // 内容
      body: !_hasPermission
          ? _buildPermissionRequest()
          : browserState.isLoading
              ? _buildLoading()
              : browserState.error != null
                  ? _buildError(browserState.error!)
                  : files.isEmpty
                      ? _buildEmpty()
                      : _buildFileList(files),
      
      // 悬浮添加按钮
      floatingActionButton: FloatingActionButton(
        onPressed: _pickFiles,
        tooltip: '添加文件',
        child: const Icon(Icons.add),
      ),
    );
  }

  /// 构建权限请求界面
  Widget _buildPermissionRequest() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.folder_off,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              '需要存储权限',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '请授予存储权限以便访问您的媒体文件',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _requestPermission,
              icon: const Icon(Icons.security),
              label: const Text('授予权限'),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建加载界面
  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('正在扫描文件...'),
        ],
      ),
    );
  }

  /// 构建错误界面
  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              '出错了',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(fileBrowserProvider.notifier).refresh();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建空状态界面
  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.music_off,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              '没有找到媒体文件',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '点击下方按钮选择文件，或选择包含媒体文件的文件夹',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _pickFiles,
              icon: const Icon(Icons.add),
              label: const Text('添加文件'),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建文件列表
  Widget _buildFileList(List<MediaItem> files) {
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(fileBrowserProvider.notifier).refresh();
      },
      child: ListView.builder(
        itemCount: files.length,
        itemBuilder: (context, index) {
          final file = files[index];
          return MediaListTile(
            media: file,
            onTap: () => _playMedia(file),
            onLongPress: () {
              // TODO: 显示更多选项
            },
            trailing: IconButton(
              icon: const Icon(Icons.playlist_add),
              onPressed: () {
                ref.read(playlistProvider.notifier).addToPlaylist(file);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('已添加到播放列表: ${file.name}'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
