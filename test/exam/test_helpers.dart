import 'package:child_doctor_app/app.dart';
import 'package:child_doctor_app/exam/exam_coordinator.dart';
import 'package:child_doctor_app/exam/exam_phase.dart';
import 'package:child_doctor_app/exam/exam_screen.dart';
import 'package:child_doctor_app/resources/asset_paths.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';

import 'fake_exam_audio.dart';

/// 设置测试窗口逻辑尺寸（dpr = 1）。
void setSurfaceSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// 设置系统字体缩放。
void setTextScale(WidgetTester tester, double scale) {
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

/// 在真实事件循环里加载真实的占位 scan.json，验证它可被 Flutter 解析。
Future<LottieComposition> loadScanComposition(WidgetTester tester) async {
  final composition = await tester.runAsync(
    () => AssetLottie(AssetPaths.scanAnimation).load(),
  );
  return composition!;
}

/// 等待真实异步任务（素材加载等）完成，然后重建一帧。
Future<void> settleAsync(
  WidgetTester tester, [
  Duration delay = const Duration(milliseconds: 100),
]) async {
  await tester.runAsync(() => Future<void>.delayed(delay));
  await tester.pump();
}

/// 等到 Lottie（含包内位图）加载结束。竖屏时主按钮不在树上，只能看资源状态。
Future<void> waitUntilResourcesResolved(
  WidgetTester tester,
  ExamCoordinator coordinator,
) async {
  for (var i = 0; i < 80; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
    if (coordinator.resourceStatus != ResourceStatus.loading) {
      await tester.pump();
      return;
    }
  }
}

/// 推进扫描动画直到自然完成。
///
/// Ticker 的第一次 tick 只记录起点（elapsed = 0），所以按 6s + 2s + 4s
/// 分段推进：6s 后进度 50%，再过 2s 越过 58% 触发虫子音效，最后 4s
/// 到达 12s。模拟的 `isDone` 判断是严格大于，最后再推进 100ms 越过时长，
/// 让状态进入 completed（累计 12.1s，仍早于 13s 的 watchdog）。
Future<void> playScanThrough(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 6));
  await tester.pump(const Duration(seconds: 2));
  await tester.pump(const Duration(seconds: 4));
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump();
}

/// 挂载完整 AppShell（真实素材异步加载）。
Future<FakeExamAudio> pumpApp(
  WidgetTester tester, {
  required Size size,
  bool waitForResources = true,
}) async {
  setSurfaceSize(tester, size);
  final audio = FakeExamAudio();
  final coordinator = ExamCoordinator(audio: audio);
  await tester.pumpWidget(AppShell(coordinator: coordinator, audio: audio));
  // 位图 Lottie 必须加载完，否则缓存里会留下未完成的 Future，拖垮后续用例。
  await waitUntilResourcesResolved(tester, coordinator);
  return audio;
}

/// 只挂载 ExamScreen（组合注入）。
Future<void> pumpExamScreen(
  WidgetTester tester, {
  required ExamCoordinator coordinator,
  LottieComposition? composition,
  Size? size,
}) async {
  if (size != null) {
    setSurfaceSize(tester, size);
  }
  await tester.pumpWidget(
    MaterialApp(
      home: ExamScreen(coordinator: coordinator, composition: composition),
    ),
  );
}
