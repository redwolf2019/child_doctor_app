import 'package:flutter/material.dart';

import 'widgets/rotate_hint_view.dart';

/// 方向门禁：用窗口宽高判断横竖，竖屏时只显示转横提示。
///
/// 通过 `WidgetsBindingObserver.didChangeMetrics` 识别方向变化，只在横竖
/// 状态真正切换时回调一次 [onOrientationChanged]；`build` 只读当前方向
/// 并渲染，不在构建过程中调用中断。
///
/// AndroidManifest 和 `SystemChrome.setPreferredOrientations` 都不能锁死
/// landscape，否则窗口尺寸永远是横屏，门禁无法识别设备被竖着拿。
class OrientationGate extends StatefulWidget {
  const OrientationGate({
    super.key,
    required this.child,
    required this.onOrientationChanged,
  });

  final Widget child;

  /// 方向真正改变时回调；`true` 表示横屏。
  final void Function(bool isLandscape) onOrientationChanged;

  @override
  State<OrientationGate> createState() => _OrientationGateState();
}

class _OrientationGateState extends State<OrientationGate>
    with WidgetsBindingObserver {
  bool _isLandscape = true;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncFromMetrics();
  }

  @override
  void didChangeMetrics() {
    _syncFromMetrics();
  }

  void _syncFromMetrics() {
    if (!mounted) {
      return;
    }
    final size = MediaQuery.sizeOf(context);
    // 只有高度严格大于宽度才是竖屏；宽高相等按横屏处理（规格：`height > width` 才显示门禁）。
    final isLandscape = size.width >= size.height;
    if (!_initialized) {
      // 首次读取只是校准当前方向，不算「变化」，不发事件。
      _initialized = true;
      _isLandscape = isLandscape;
      return;
    }
    if (isLandscape != _isLandscape) {
      _isLandscape = isLandscape;
      widget.onOrientationChanged(isLandscape);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isLandscape = size.width >= size.height;
    return isLandscape ? widget.child : const RotateHintView();
  }
}
