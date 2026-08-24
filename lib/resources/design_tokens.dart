import 'package:flutter/material.dart';

/// 视觉 tokens。检查室插画和扫描关键帧到位后，Golden 基线与这里一起改，不散落硬编码。
abstract final class DesignTokens {
  /// 舞台外留边色（与检查室背景协调的深色）。
  static const stageOutside = Color(0xFF16324F);

  /// 主按钮背景。
  static const primaryButton = Color(0xFFFFB703);

  /// 主按钮描边，略深于填充，做成厚卡片边。
  static const primaryButtonBorder = Color(0xFFE09A00);

  /// 主按钮文字。
  static const primaryButtonText = Color(0xFF3A2A00);

  /// 结果提示板底色。
  static const resultPanel = Color(0xFFFFF8E7);

  /// 结果提示板不透明，保证字在浅蓝墙上可读，也不透出虫子抢对比。
  static const resultPanelOpacity = 0.96;

  /// 结果提示板描边。
  static const resultPanelBorder = Color(0xFFE9C46A);

  /// 正文颜色。
  static const bodyText = Color(0xFF203040);

  /// 主按钮最小可点击区域。
  static const minPrimaryButtonSize = Size(160, 64);

  /// 主按钮最小字号。
  static const minPrimaryButtonFontSize = 22.0;

  /// 洗手提示字号。右侧窄板按 22sp 排，系统 1.3 倍时仍完整换行。
  static const washHintFontSize = 22.0;

  /// 业务舞台比例（16:9）。
  static const stageAspectRatio = 16 / 9;

  /// 虫子音效点：动画进度首次达到该值时播放一次虫子音效。
  /// 正式动画调整虫子出现时间时必须同步修改该值和音画同步测试。
  static const wormCueProgress = 0.58;

  /// 结果提示板宽度相对舞台宽度的最大比例。贴在右侧，给肚子近景留空。
  static const resultPanelMaxWidthRatio = 0.38;

  /// 洗手提示最多行数。右侧窄板需要多于两行才能放下固定原文。
  static const washHintMaxLines = 4;

  /// 主按钮统一样式（检查室「开始扫描」和结果页「再看一次」共用）。
  static ButtonStyle primaryButtonStyle() => FilledButton.styleFrom(
    backgroundColor: primaryButton,
    foregroundColor: primaryButtonText,
    minimumSize: minPrimaryButtonSize,
    elevation: 2,
    shadowColor: const Color(0x663A2A00),
    side: const BorderSide(color: primaryButtonBorder, width: 3),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    textStyle: const TextStyle(
      fontSize: minPrimaryButtonFontSize,
      fontWeight: FontWeight.w700,
    ),
  );
}
