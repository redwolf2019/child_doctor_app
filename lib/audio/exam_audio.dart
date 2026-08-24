/// 检查音频编排接口。隐藏播放器数量、循环、资源和停止行为。
///
/// 生产实现见 `LocalAudio`，测试替身见 `test/exam/fake_exam_audio.dart`。
/// 所有方法都可能因平台错误失败；调用方按设计静默降级，不把音频失败
/// 变成扫描失败。
abstract interface class ExamAudio {
  /// 准备本地音频源（不播放）。失败按静默降级处理。
  Future<void> prepare();

  /// 从头循环播放扫描底音。
  Future<void> startScanBed();

  /// 停止扫描底音。
  Future<void> stopScanBed();

  /// 播放一次虫子音效。
  Future<void> playWormCue();

  /// 播放一次洗手配音（不循环）。
  Future<void> playWashHint();

  /// 停止全部播放器。可重复调用；平台错误由调用方按设计静默降级。
  Future<void> stopAll();

  /// 释放全部播放器。可重复调用。
  Future<void> dispose();
}
