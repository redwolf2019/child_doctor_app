import 'package:flutter/material.dart';

import '../../resources/copy.dart';
import '../../resources/design_tokens.dart';

/// 竖屏门禁：纯色背景、横向设备图标和转横提示。
/// 整页语义为 `rotateHint`，图标和可见文字不出现在独立语义节点里。
class RotateHintView extends StatelessWidget {
  const RotateHintView({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: Copy.rotateHint,
      container: true,
      child: ExcludeSemantics(
        child: ColoredBox(
          color: DesignTokens.stageOutside,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _LandscapeDeviceIcon(),
                const SizedBox(height: 24),
                const Text(
                  Copy.rotateHint,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 横向设备图标：横长的圆角矩形 + 一个摄像头圆点，无文字。
class _LandscapeDeviceIcon extends StatelessWidget {
  const _LandscapeDeviceIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 132,
      height: 76,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white, width: 3),
      ),
      alignment: Alignment.center,
      child: Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
