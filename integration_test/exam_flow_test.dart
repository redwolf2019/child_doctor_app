// 覆盖说明：
// - I04 扫描中转竖屏：真机窗口尺寸由系统传感器驱动，测试无法注入
//   metrics 变化；自动化证据见 test/exam/app_shell_test.dart
//   「扫描中转竖屏」，真机证据见 A07。
// - I06 三态系统返回：SystemNavigator.pop 会真的关闭 Activity、终止
//   测试进程；中断先于关闭的自动化证据见 test/exam/app_shell_test.dart
//   「三态系统返回」，真机证据见 A09。
// - I07 飞行模式：飞行模式需 adb shell 控制，无法在测试内切换；
//   离线能力由「无 INTERNET 权限」清单检查保证，真机证据见 A10。

import 'dart:ui' show AppLifecycleState;

import 'package:child_doctor_app/app.dart';
import 'package:child_doctor_app/audio/exam_audio.dart';
import 'package:child_doctor_app/audio/local_audio.dart';
import 'package:child_doctor_app/exam/exam_coordinator.dart';
import 'package:child_doctor_app/exam/exam_phase.dart';
import 'package:child_doctor_app/resources/copy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// 记录调用并委托真实 LocalAudio：真机流程中使用真实素材播放，
/// 同时断言音频编排次数。
class CountingAudio implements ExamAudio {
  CountingAudio(this._inner);

  final LocalAudio _inner;
  int startScanBedCount = 0;
  int stopScanBedCount = 0;
  int playWormCueCount = 0;
  int playWashHintCount = 0;
  int stopAllCount = 0;

  @override
  Future<void> prepare() => _inner.prepare();

  @override
  Future<void> startScanBed() {
    startScanBedCount++;
    return _inner.startScanBed();
  }

  @override
  Future<void> stopScanBed() {
    stopScanBedCount++;
    return _inner.stopScanBed();
  }

  @override
  Future<void> playWormCue() {
    playWormCueCount++;
    return _inner.playWormCue();
  }

  @override
  Future<void> playWashHint() {
    playWashHintCount++;
    return _inner.playWashHint();
  }

  @override
  Future<void> stopAll() {
    stopAllCount++;
    return _inner.stopAll();
  }

  @override
  Future<void> dispose() => _inner.dispose();
}

/// 等待一次完整扫描（12 秒正式时长）自然结束并稳定下来。
Future<void> waitForResult(WidgetTester tester) async {
  await tester.pumpAndSettle(
    const Duration(milliseconds: 100),
    EnginePhase.sendSemanticsUpdate,
    const Duration(seconds: 30),
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late CountingAudio audio;
  late ExamCoordinator coordinator;

  Future<void> pumpRealApp(WidgetTester tester) async {
    audio = CountingAudio(LocalAudio());
    coordinator = ExamCoordinator(audio: audio);
    await tester.pumpWidget(AppShell(coordinator: coordinator, audio: audio));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
  }

  testWidgets('I01 横屏完整流程：开始→扫描→结果，配音一次', (tester) async {
    await pumpRealApp(tester);

    expect(coordinator.phase, ExamPhase.ready);
    expect(find.text(Copy.startScan), findsOneWidget);

    await tester.tap(find.text(Copy.startScan));
    await tester.pump();
    expect(coordinator.phase, ExamPhase.scanning);
    expect(audio.startScanBedCount, 1);

    await waitForResult(tester);
    expect(coordinator.phase, ExamPhase.result);
    expect(find.text(Copy.washHint), findsOneWidget);
    expect(audio.stopScanBedCount, 1);
    expect(audio.playWashHintCount, 1);
  });

  testWidgets('I02 重复点击：连点开始只启动一轮', (tester) async {
    await pumpRealApp(tester);

    await tester.tap(find.text(Copy.startScan));
    for (var i = 0; i < 4; i++) {
      await tester.tapAt(tester.getCenter(find.byType(AppShell)));
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(coordinator.runId, 1);
    expect(audio.startScanBedCount, 1);

    await waitForResult(tester);
    expect(coordinator.phase, ExamPhase.result);
    expect(audio.playWashHintCount, 1);
  });

  testWidgets('I03 再看一次：从结果直接从第 0 帧开始新扫描', (tester) async {
    await pumpRealApp(tester);

    await tester.tap(find.text(Copy.startScan));
    await waitForResult(tester);
    expect(coordinator.phase, ExamPhase.result);

    await tester.tap(find.text(Copy.replay));
    await tester.pump();
    expect(coordinator.phase, ExamPhase.scanning);
    expect(coordinator.runId, 2);
    expect(audio.startScanBedCount, 2);

    await waitForResult(tester);
    expect(coordinator.phase, ExamPhase.result);
    expect(audio.playWormCueCount, 2); // 每轮各一次
    expect(audio.playWashHintCount, 2);
  });

  testWidgets('I05 扫描中切后台：后台无音频，回来显示检查室', (tester) async {
    await pumpRealApp(tester);

    await tester.tap(find.text(Copy.startScan));
    await tester.pump();
    expect(coordinator.phase, ExamPhase.scanning);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(milliseconds: 300));
    expect(coordinator.phase, ExamPhase.ready);
    expect(audio.stopAllCount, greaterThanOrEqualTo(1));

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(Copy.startScan), findsOneWidget);
    expect(coordinator.phase, ExamPhase.ready);

    // 恢复后仍可正常完成一轮
    await tester.tap(find.text(Copy.startScan));
    await waitForResult(tester);
    expect(coordinator.phase, ExamPhase.result);
  });

  testWidgets('I08 连续重播 20 轮：无崩溃、无叠音', (tester) async {
    await pumpRealApp(tester);

    await tester.tap(find.text(Copy.startScan));
    await waitForResult(tester);

    for (var round = 2; round <= 20; round++) {
      await tester.tap(find.text(Copy.replay));
      await tester.pump();
      await waitForResult(tester);
      expect(coordinator.phase, ExamPhase.result);
    }

    // 20 轮：每轮一次底音启动、一次虫子音效、一次配音；无叠加。
    expect(audio.startScanBedCount, 20);
    expect(audio.playWormCueCount, 20);
    expect(audio.playWashHintCount, 20);
  });
}
