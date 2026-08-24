import 'package:flutter/material.dart';

import '../../resources/copy.dart';
import '../../resources/design_tokens.dart';

/// 洗手提示叠加层：保留 Lottie 末帧，叠加宽度不超过舞台 75% 的浅色
/// 半透明提示板，包含不超过两行的固定文案和「再看一次」。
class ResultView extends StatelessWidget {
  const ResultView({super.key, required this.onReplay});

  final VoidCallback onReplay;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: FractionallySizedBox(
        widthFactor: DesignTokens.resultPanelMaxWidthRatio,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          decoration: BoxDecoration(
            color: DesignTokens.resultPanel.withValues(
              alpha: DesignTokens.resultPanelOpacity,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                Copy.washHint,
                maxLines: 2,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: DesignTokens.bodyText,
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                style: DesignTokens.primaryButtonStyle(),
                onPressed: onReplay,
                child: const Text(Copy.replay),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
