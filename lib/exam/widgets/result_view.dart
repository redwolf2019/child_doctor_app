import 'package:flutter/material.dart';

import '../../resources/copy.dart';
import '../../resources/design_tokens.dart';

/// 洗手提示叠加层：保留 Lottie 末帧，提示板贴在舞台右侧，
/// 文案和「再看一次」左对齐，不挡住肚子近景里的虫子。
class ResultView extends StatelessWidget {
  const ResultView({super.key, required this.onReplay});

  final VoidCallback onReplay;

  /// 结果提示板，供宽度和位置测试定位。
  static const panelKey = ValueKey('result-panel');

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: FractionallySizedBox(
        widthFactor: DesignTokens.resultPanelMaxWidthRatio,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 24, 16, 24),
          child: Container(
            key: panelKey,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            decoration: BoxDecoration(
              color: DesignTokens.resultPanel.withValues(
                alpha: DesignTokens.resultPanelOpacity,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: DesignTokens.resultPanelBorder,
                width: 3,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  offset: Offset(2, 6),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  Copy.washHint,
                  maxLines: DesignTokens.washHintMaxLines,
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    color: DesignTokens.bodyText,
                    fontSize: DesignTokens.washHintFontSize,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  style: DesignTokens.primaryButtonStyle(),
                  onPressed: onReplay,
                  child: const Text(Copy.replay),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
