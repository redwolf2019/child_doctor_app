import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// 扫描画面：全屏 Lottie（包内关键帧交叉淡化），没有按钮。普通点击、双击和长按都没有业务效果。
///
/// 在 `scanning` 与 `result` 期间保持挂载；控制器由 `ExamScreen` 持有，
/// 保证两个状态之间动画连续，进入 `result` 时停在末帧。
class ScanningView extends StatelessWidget {
  const ScanningView({
    super.key,
    required this.composition,
    required this.controller,
  });

  final LottieComposition composition;
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return Lottie(
      composition: composition,
      controller: controller,
      fit: BoxFit.contain,
      animate: false,
      repeat: false,
    );
  }
}
