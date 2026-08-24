import 'package:flutter/material.dart';

/// 占位设计 tokens。正式视觉稿到位后统一替换这里和 Golden 基线，不散落硬编码。
abstract final class DesignTokens {
  /// 舞台外留边色（与检查室背景协调的深色）。
  static const stageOutside = Color(0xFF16324F);

  /// 主按钮背景。
  static const primaryButton = Color(0xFFFFB703);

  /// 主按钮文字。
  static const primaryButtonText = Color(0xFF3A2A00);

  /// 结果提示板底色，94% 不透明。
  static const resultPanel = Color(0xFFFFF8E7);
  static const resultPanelOpacity = 0.94;

  /// 正文颜色。
  static const bodyText = Color(0xFF203040);

  /// 主按钮最小可点击区域。
  static const minPrimaryButtonSize = Size(160, 64);

  /// 主按钮最小字号。
  static const minPrimaryButtonFontSize = 22.0;

  /// 业务舞台比例（16:9）。
  static const stageAspectRatio = 16 / 9;

  /// 虫子音效点：动画进度首次达到该值时播放一次虫子音效。
  /// 正式动画调整虫子出现时间时必须同步修改该值和音画同步测试。
  static const wormCueProgress = 0.58;

  /// 结果提示板宽度相对舞台宽度的最大比例。
  static const resultPanelMaxWidthRatio = 0.75;

  /// 主按钮统一样式（检查室「开始扫描」和结果页「再看一次」共用）。
  static ButtonStyle primaryButtonStyle() => FilledButton.styleFrom(
    backgroundColor: primaryButton,
    foregroundColor: primaryButtonText,
    minimumSize: minPrimaryButtonSize,
    textStyle: const TextStyle(
      fontSize: minPrimaryButtonFontSize,
      fontWeight: FontWeight.w700,
    ),
  );
}
