import 'package:flutter/material.dart';

import '../../resources/asset_paths.dart';
import '../../resources/copy.dart';
import '../../resources/design_tokens.dart';
import '../exam_phase.dart';

/// 检查室（`ready`）：卡通检查室背景 + 底部唯一主按钮。
///
/// 资源仍在加载时显示不旋转的「正在准备…」；加载失败显示固定错误文案，
/// 不展示点了也无法工作的按钮。
class ReadyView extends StatelessWidget {
  const ReadyView({
    super.key,
    required this.resourceStatus,
    required this.onStartScan,
  });

  final ResourceStatus resourceStatus;
  final VoidCallback onStartScan;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(AssetPaths.examRoomImage, fit: BoxFit.contain),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 36),
            child: _StatusArea(
              resourceStatus: resourceStatus,
              onStartScan: onStartScan,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusArea extends StatelessWidget {
  const _StatusArea({required this.resourceStatus, required this.onStartScan});

  final ResourceStatus resourceStatus;
  final VoidCallback onStartScan;

  @override
  Widget build(BuildContext context) {
    switch (resourceStatus) {
      case ResourceStatus.loading:
        return const Text(
          Copy.preparing,
          style: TextStyle(
            color: DesignTokens.bodyText,
            fontSize: 24,
            fontWeight: FontWeight.w500,
          ),
        );
      case ResourceStatus.ready:
        return FilledButton(
          style: DesignTokens.primaryButtonStyle(),
          onPressed: onStartScan,
          child: const Text(Copy.startScan),
        );
      case ResourceStatus.failed:
        return const Text(
          Copy.loadFailed,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: DesignTokens.bodyText,
            fontSize: 24,
            fontWeight: FontWeight.w500,
          ),
        );
    }
  }
}
