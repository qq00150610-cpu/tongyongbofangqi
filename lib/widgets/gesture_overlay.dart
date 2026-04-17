import 'package:flutter/material.dart';

/// 手势操作覆盖层
/// 
/// 处理播放器中的各种手势操作：
/// - 点击：显示/隐藏控制栏
/// - 水平滑动：调节播放进度
/// - 垂直滑动（左侧）：调节亮度
/// - 垂直滑动（右侧）：调节音量
class GestureOverlay extends StatefulWidget {
  /// 子组件
  final Widget child;
  
  /// 点击回调
  final VoidCallback? onTap;
  
  /// 双击回调
  final VoidCallback? onDoubleTap;
  
  /// 水平滑动结束回调
  final ValueChanged<DragEndDetails>? onHorizontalDragEnd;
  
  /// 垂直滑动结束回调（左侧）
  final ValueChanged<double>? onBrightnessChange;
  
  /// 垂直滑动结束回调（右侧）
  final ValueChanged<double>? onVolumeChange;
  
  /// 左侧是否控制亮度（否则控制进度）
  final bool leftSideControlsBrightness;

  const GestureOverlay({
    super.key,
    required this.child,
    this.onTap,
    this.onDoubleTap,
    this.onHorizontalDragEnd,
    this.onBrightnessChange,
    this.onVolumeChange,
    this.leftSideControlsBrightness = true,
  });

  @override
  State<GestureOverlay> createState() => _GestureOverlayState();
}

class _GestureOverlayState extends State<GestureOverlay> {
  /// 水平滑动距离
  double _horizontalDragDistance = 0;
  
  /// 垂直滑动距离（左侧）
  double _leftVerticalDragDistance = 0;
  
  /// 垂直滑动距离（右侧）
  double _rightVerticalDragDistance = 0;
  
  /// 滑动起始位置X
  double? _dragStartX;
  
  /// 滑动起始位置Y
  double? _dragStartY;
  
  /// 是否水平滑动
  bool _isHorizontalDrag = false;
  
  /// 是否垂直滑动（左侧）
  bool _isLeftVerticalDrag = false;
  
  /// 是否垂直滑动（右侧）
  bool _isRightVerticalDrag = false;
  
  /// 灵敏度系数
  static const double _sensitivity = 0.5;
  
  /// 垂直滑动阈值
  static const double _verticalThreshold = 50.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: widget.onTap,
      onDoubleTap: widget.onDoubleTap,
      
      // 水平滑动
      onHorizontalDragStart: (details) {
        _dragStartX = details.localPosition.dx;
        _horizontalDragDistance = 0;
        _isHorizontalDrag = true;
        _isLeftVerticalDrag = false;
        _isRightVerticalDrag = false;
      },
      onHorizontalDragUpdate: (details) {
        if (_isHorizontalDrag && _dragStartX != null) {
          _horizontalDragDistance += details.delta.dx;
        }
      },
      onHorizontalDragEnd: (details) {
        if (_isHorizontalDrag && _horizontalDragDistance.abs() > _verticalThreshold) {
          // 触发进度调节
          widget.onHorizontalDragEnd?.call(details);
        }
        _resetDragState();
      },
      
      // 左侧垂直滑动
      onVerticalDragStart: (details) {
        _dragStartY = details.localPosition.dy;
        _isHorizontalDrag = false;
        _isLeftVerticalDrag = false;
        _isRightVerticalDrag = false;
        
        // 判断是左侧还是右侧
        if (_dragStartX != null) {
          final screenWidth = MediaQuery.of(context).size.width;
          if (_dragStartX! < screenWidth / 2) {
            _isLeftVerticalDrag = true;
            _leftVerticalDragDistance = 0;
          } else {
            _isRightVerticalDrag = true;
            _rightVerticalDragDistance = 0;
          }
        }
      },
      onVerticalDragUpdate: (details) {
        if (_isLeftVerticalDrag) {
          _leftVerticalDragDistance += details.delta.dy;
        } else if (_isRightVerticalDrag) {
          _rightVerticalDragDistance += details.delta.dy;
        }
      },
      onVerticalDragEnd: (details) {
        if (_isLeftVerticalDrag && _leftVerticalDragDistance.abs() > _verticalThreshold) {
          final change = -_leftVerticalDragDistance * _sensitivity / 200;
          widget.onBrightnessChange?.call(change);
        } else if (_isRightVerticalDrag && _rightVerticalDragDistance.abs() > _verticalThreshold) {
          final change = -_rightVerticalDragDistance * _sensitivity / 200;
          widget.onVolumeChange?.call(change);
        }
        _resetDragState();
      },
      
      // 取消操作
      onPanCancel: _resetDragState,
      
      child: widget.child,
    );
  }

  /// 重置滑动状态
  void _resetDragState() {
    _dragStartX = null;
    _dragStartY = null;
    _horizontalDragDistance = 0;
    _leftVerticalDragDistance = 0;
    _rightVerticalDragDistance = 0;
    _isHorizontalDrag = false;
    _isLeftVerticalDrag = false;
    _isRightVerticalDrag = false;
  }
}

/// 双击区域检测
class DoubleTapArea extends StatelessWidget {
  /// 子组件
  final Widget child;
  
  /// 左侧双击回调
  final VoidCallback? onLeftDoubleTap;
  
  /// 右侧双击回调
  final VoidCallback? onRightDoubleTap;
  
  /// 中间双击回调
  final VoidCallback? onCenterDoubleTap;

  const DoubleTapArea({
    super.key,
    required this.child,
    this.onLeftDoubleTap,
    this.onRightDoubleTap,
    this.onCenterDoubleTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        // 左侧区域
        Positioned.fill(
          left: 0,
          right: MediaQuery.of(context).size.width * 2 / 3,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onDoubleTap: onLeftDoubleTap,
          ),
        ),
        // 右侧区域
        Positioned.fill(
          left: MediaQuery.of(context).size.width / 3,
          right: 0,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onDoubleTap: onRightDoubleTap,
          ),
        ),
        // 中间区域
        Positioned(
          left: MediaQuery.of(context).size.width / 3,
          right: MediaQuery.of(context).size.width / 3,
          top: 0,
          bottom: 0,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onDoubleTap: onCenterDoubleTap,
          ),
        ),
      ],
    );
  }
}
