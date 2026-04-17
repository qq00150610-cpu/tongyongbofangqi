import 'package:flutter/material.dart';

/// 进度条组件
/// 
/// 支持拖动的播放进度条
class ProgressBar extends StatefulWidget {
  /// 当前播放位置
  final Duration position;
  
  /// 总时长
  final Duration duration;
  
  /// 缓冲进度 (0.0 - 1.0)
  final double? buffer;
  
  /// 跳转回调
  final ValueChanged<Duration>? onSeek;
  
  /// 是否可拖动
  final bool canSeek;
  
  /// 高度
  final double height;

  const ProgressBar({
    super.key,
    required this.position,
    required this.duration,
    this.buffer,
    this.onSeek,
    this.canSeek = true,
    this.height = 4.0,
  });

  @override
  State<ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends State<ProgressBar> {
  bool _isDragging = false;
  double _dragValue = 0.0;
  
  /// 获取当前进度值 (0.0 - 1.0)
  double get _progress {
    if (widget.duration.inMilliseconds == 0) return 0.0;
    if (_isDragging) return _dragValue;
    return widget.position.inMilliseconds / widget.duration.inMilliseconds;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        
        return GestureDetector(
          onHorizontalDragStart: widget.canSeek ? _onDragStart : null,
          onHorizontalDragUpdate: widget.canSeek 
              ? (details) => _onDragUpdate(details, width) 
              : null,
          onHorizontalDragEnd: widget.canSeek ? _onDragEnd : null,
          onTapUp: widget.canSeek ? (details) => _onTap(details, width) : null,
          child: Container(
            height: 48, // 扩大点击区域
            padding: const EdgeInsets.symmetric(vertical: 22),
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                // 背景轨道
                Container(
                  height: widget.height,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(widget.height / 2),
                  ),
                ),
                
                // 缓冲进度
                if (widget.buffer != null)
                  FractionallySizedBox(
                    widthFactor: widget.buffer!.clamp(0.0, 1.0),
                    child: Container(
                      height: widget.height,
                      decoration: BoxDecoration(
                        color: Colors.white38,
                        borderRadius: BorderRadius.circular(widget.height / 2),
                      ),
                    ),
                  ),
                
                // 播放进度
                FractionallySizedBox(
                  widthFactor: _progress.clamp(0.0, 1.0),
                  child: Container(
                    height: widget.height,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(widget.height / 2),
                    ),
                  ),
                ),
                
                // 滑块
                Positioned(
                  left: (_progress.clamp(0.0, 1.0) * width) - 8,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 开始拖动
  void _onDragStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
      _dragValue = _progress;
    });
  }

  /// 拖动中
  void _onDragUpdate(DragUpdateDetails details, double width) {
    setState(() {
      _dragValue = (_dragValue + details.delta.dx / width).clamp(0.0, 1.0);
    });
  }

  /// 结束拖动
  void _onDragEnd(DragEndDetails details) {
    final newPosition = Duration(
      milliseconds: (_dragValue * widget.duration.inMilliseconds).toInt(),
    );
    widget.onSeek?.call(newPosition);
    
    setState(() {
      _isDragging = false;
    });
  }

  /// 点击
  void _onTap(TapUpDetails details, double width) {
    final newProgress = (details.localPosition.dx / width).clamp(0.0, 1.0);
    final newPosition = Duration(
      milliseconds: (newProgress * widget.duration.inMilliseconds).toInt(),
    );
    widget.onSeek?.call(newPosition);
  }
}

/// 迷你进度条（不可拖动）
class MiniProgressBar extends StatelessWidget {
  final double progress;
  final double height;
  
  const MiniProgressBar({
    super.key,
    required this.progress,
    this.height = 3.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            borderRadius: BorderRadius.circular(height / 2),
          ),
        ),
      ),
    );
  }
}
