import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/media_item.dart';
import '../services/file_service.dart';

/// 文件浏览器Provider
/// 
/// 管理文件浏览的所有状态：
/// - 当前目录
/// - 文件列表
/// - 排序方式
/// - 搜索结果
class FileBrowserNotifier extends StateNotifier<FileBrowserState> {
  final FileService _fileService;
  
  FileBrowserNotifier(this._fileService) : super(FileBrowserState.initial) {
    _init();
  }
  
  /// 初始化
  Future<void> _init() async {
    // 获取外部存储路径
    final paths = await _fileService.getExternalStoragePaths();
    if (paths.isNotEmpty) {
      await navigateToDirectory(paths.first);
    }
  }
  
  /// 导航到指定目录
  Future<void> navigateToDirectory(String path) async {
    state = state.copyWith(
      currentPath: path,
      isLoading: true,
      error: null,
    );
    
    try {
      final mediaFiles = await _fileService.scanDirectory(path);
      
      // 应用当前排序
      final sortedFiles = _sortFiles(mediaFiles, state.sortBy, state.sortAscending);
      
      state = state.copyWith(
        files: sortedFiles,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
  
  /// 返回上级目录
  Future<void> navigateBack() async {
    final currentPath = state.currentPath;
    final lastSlash = currentPath.lastIndexOf('/');
    
    if (lastSlash > 0) {
      final parentPath = currentPath.substring(0, lastSlash);
      await navigateToDirectory(parentPath);
    }
  }
  
  /// 选择目录
  Future<void> pickDirectory() async {
    final path = await _fileService.pickDirectory();
    if (path != null) {
      await navigateToDirectory(path);
    }
  }
  
  /// 刷新当前目录
  Future<void> refresh() async {
    if (state.currentPath.isNotEmpty) {
      await navigateToDirectory(state.currentPath);
    }
  }
  
  /// 排序文件
  Future<void> sortBy(FileSortBy sortBy) async {
    final ascending = state.sortBy == sortBy ? !state.sortAscending : true;
    final sortedFiles = _sortFiles(state.files, sortBy, ascending);
    
    state = state.copyWith(
      files: sortedFiles,
      sortBy: sortBy,
      sortAscending: ascending,
    );
  }
  
  /// 排序文件列表
  List<MediaItem> _sortFiles(
    List<MediaItem> files,
    FileSortBy sortBy,
    bool ascending,
  ) {
    final sortedFiles = [...files];
    
    switch (sortBy) {
      case FileSortBy.name:
        sortedFiles.sort((a, b) => ascending
            ? a.name.compareTo(b.name)
            : b.name.compareTo(a.name));
        break;
      case FileSortBy.size:
        sortedFiles.sort((a, b) => ascending
            ? a.size.compareTo(b.size)
            : b.size.compareTo(a.size));
        break;
      case FileSortBy.date:
        sortedFiles.sort((a, b) => ascending
            ? a.createdAt.compareTo(b.createdAt)
            : b.createdAt.compareTo(a.createdAt));
        break;
      case FileSortBy.type:
        sortedFiles.sort((a, b) => ascending
            ? a.extension.compareTo(b.extension)
            : b.extension.compareTo(a.extension));
        break;
    }
    
    return sortedFiles;
  }
  
  /// 搜索文件
  Future<void> search(String query) async {
    state = state.copyWith(searchQuery: query);
    
    if (query.isEmpty) {
      state = state.copyWith(filteredFiles: null);
      return;
    }
    
    final lowerQuery = query.toLowerCase();
    final filtered = state.files.where((file) {
      return file.name.toLowerCase().contains(lowerQuery) ||
          file.extension.toLowerCase().contains(lowerQuery);
    }).toList();
    
    state = state.copyWith(filteredFiles: filtered);
  }
  
  /// 清除搜索
  void clearSearch() {
    state = state.copyWith(searchQuery: '', filteredFiles: null);
  }
  
  /// 按类型筛选
  Future<void> filterByType(MediaType? type) async {
    state = state.copyWith(filterType: type);
  }
  
  /// 添加选中的文件
  void toggleFileSelection(MediaItem file) {
    final selectedFiles = [...state.selectedFiles];
    
    if (selectedFiles.contains(file)) {
      selectedFiles.remove(file);
    } else {
      selectedFiles.add(file);
    }
    
    state = state.copyWith(selectedFiles: selectedFiles);
  }
  
  /// 清除选中
  void clearSelection() {
    state = state.copyWith(selectedFiles: []);
  }
  
  /// 全选
  void selectAll() {
    state = state.copyWith(selectedFiles: [...state.files]);
  }
  
  /// 获取显示的文件列表
  List<MediaItem> get displayFiles {
    if (state.filteredFiles != null) {
      return state.filteredFiles!;
    }
    
    if (state.filterType != null) {
      return state.files.where((f) => f.type == state.filterType).toList();
    }
    
    return state.files;
  }
}

/// 文件排序方式
enum FileSortBy {
  name,
  size,
  date,
  type,
}

/// 文件排序方式扩展
extension FileSortByExtension on FileSortBy {
  String get displayName {
    switch (this) {
      case FileSortBy.name:
        return '名称';
      case FileSortBy.size:
        return '大小';
      case FileSortBy.date:
        return '日期';
      case FileSortBy.type:
        return '类型';
    }
  }
}

/// 文件浏览器状态
class FileBrowserState {
  /// 当前目录路径
  final String currentPath;
  
  /// 文件列表
  final List<MediaItem> files;
  
  /// 过滤后的文件列表（搜索时）
  final List<MediaItem>? filteredFiles;
  
  /// 排序方式
  final FileSortBy sortBy;
  
  /// 是否升序
  final bool sortAscending;
  
  /// 搜索关键词
  final String searchQuery;
  
  /// 筛选类型
  final MediaType? filterType;
  
  /// 是否加载中
  final bool isLoading;
  
  /// 错误信息
  final String? error;
  
  /// 选中的文件
  final List<MediaItem> selectedFiles;
  
  /// 是否全选
  bool get isAllSelected {
    return files.isNotEmpty && selectedFiles.length == files.length;
  }
  
  const FileBrowserState({
    this.currentPath = '',
    this.files = const [],
    this.filteredFiles,
    this.sortBy = FileSortBy.name,
    this.sortAscending = true,
    this.searchQuery = '',
    this.filterType,
    this.isLoading = false,
    this.error,
    this.selectedFiles = const [],
  });
  
  /// 初始状态
  static const FileBrowserState initial = FileBrowserState();
  
  /// 文件数量
  int get fileCount => files.length;
  
  /// 是否有文件
  bool get hasFiles => files.isNotEmpty;
  
  /// 是否有选中
  bool get hasSelection => selectedFiles.isNotEmpty;
  
  /// 音频数量
  int get audioCount => files.where((f) => f.type == MediaType.audio).length;
  
  /// 视频数量
  int get videoCount => files.where((f) => f.type == MediaType.video).length;
  
  FileBrowserState copyWith({
    String? currentPath,
    List<MediaItem>? files,
    List<MediaItem>? filteredFiles,
    bool clearFiltered = false,
    FileSortBy? sortBy,
    bool? sortAscending,
    String? searchQuery,
    MediaType? filterType,
    bool clearFilter = false,
    bool? isLoading,
    String? error,
    bool clearError = false,
    List<MediaItem>? selectedFiles,
  }) {
    return FileBrowserState(
      currentPath: currentPath ?? this.currentPath,
      files: files ?? this.files,
      filteredFiles: clearFiltered ? null : (filteredFiles ?? this.filteredFiles),
      sortBy: sortBy ?? this.sortBy,
      sortAscending: sortAscending ?? this.sortAscending,
      searchQuery: searchQuery ?? this.searchQuery,
      filterType: clearFilter ? null : (filterType ?? this.filterType),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      selectedFiles: selectedFiles ?? this.selectedFiles,
    );
  }
}

/// 文件浏览器Provider
final fileBrowserProvider = StateNotifierProvider<FileBrowserNotifier, FileBrowserState>((ref) {
  return FileBrowserNotifier(FileService.instance);
});

/// 显示文件列表Provider
final displayFilesProvider = Provider<List<MediaItem>>((ref) {
  final browser = ref.watch(fileBrowserProvider.notifier);
  return browser.displayFiles;
});

/// 音频文件Provider
final audioFilesProvider = Provider<List<MediaItem>>((ref) {
  final state = ref.watch(fileBrowserProvider);
  return state.files.where((f) => f.type == MediaType.audio).toList();
});

/// 视频文件Provider
final videoFilesProvider = Provider<List<MediaItem>>((ref) {
  final state = ref.watch(fileBrowserProvider);
  return state.files.where((f) => f.type == MediaType.video).toList();
});
