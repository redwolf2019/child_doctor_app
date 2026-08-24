import 'package:child_doctor_app/app.dart';
import 'package:child_doctor_app/exam/exam_coordinator.dart';
import 'package:child_doctor_app/exam/exam_phase.dart';
import 'package:child_doctor_app/exam/widgets/rotate_hint_view.dart';
import 'package:child_doctor_app/resources/copy.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_exam_audio.dart';
import 'test_helpers.dart';

void main() {
  late FakeExamAudio audio;
  late ExamCoordinator coordinator;

  Future<void> pumpShell(
    WidgetTester tester, {
    Size size = const Size(640, 360),
  }) async {
    setSurfaceSize(tester, size);
    audio = FakeExamAudio();
    coordinator = ExamCoordinator(audio: audio);
    await tester.pumpWidget(AppShell(coordinator: coordinator, audio: audio));
    await waitUntilResourcesResolved(tester, coordinator);
  }

  testWidgets('切后台执行 abort，回来后是检查室', (tester) async {
    await pumpShell(tester);

    await tester.tap(find.text(Copy.startScan));
    await tester.pump();
    expect(coordinator.phase, ExamPhase.scanning);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(coordinator.phase, ExamPhase.scanning); // inactive 不迁移

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(coordinator.phase, ExamPhase.ready);
    expect(audio.count('stopAll'), 1);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.tap(find.text(Copy.startScan));
    await tester.pump();
    expect(coordinator.phase, ExamPhase.scanning); // 恢复后可再次开始
  });

  testWidgets('resumed 重新应用沉浸式显示', (tester) async {
    final messages = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        messages.add(call.method);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await pumpShell(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    final immersiveCallsBefore = messages
        .where((m) => m == 'SystemChrome.setEnabledSystemUIMode')
        .length;

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    final immersiveCallsAfter = messages
        .where((m) => m == 'SystemChrome.setEnabledSystemUIMode')
        .length;
    expect(immersiveCallsAfter, immersiveCallsBefore + 1);
  });

  testWidgets('扫描中转竖屏：立即中断，转回横屏显示检查室', (tester) async {
    await pumpShell(tester);

    await tester.tap(find.text(Copy.startScan));
    await tester.pump();
    expect(coordinator.phase, ExamPhase.scanning);

    tester.view.physicalSize = const Size(360, 800);
    await tester.pump();
    expect(find.byType(RotateHintView), findsOneWidget);
    expect(coordinator.phase, ExamPhase.ready);
    expect(audio.count('stopAll'), 1);

    tester.view.physicalSize = const Size(800, 360);
    await tester.pump();
    expect(find.byType(RotateHintView), findsNothing);
    expect(find.text(Copy.startScan), findsOneWidget);
  });

  testWidgets('三态系统返回：先 abort 再关闭 Activity', (tester) async {
    await pumpShell(tester);

    for (final phase in [
      ExamPhase.ready,
      ExamPhase.scanning,
      ExamPhase.result,
    ]) {
      if (phase == ExamPhase.scanning) {
        await tester.tap(find.text(Copy.startScan));
        await tester.pump();
      } else if (phase == ExamPhase.result) {
        await tester.tap(find.text(Copy.startScan));
        await playScanThrough(tester);
      }
      expect(coordinator.phase, phase);

      final stopAllBefore = audio.count('stopAll');
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(coordinator.phase, ExamPhase.ready);
      // ready 态没有副作用要停，abort 是空操作；其他状态停一次全部音频。
      expect(
        audio.count('stopAll'),
        phase == ExamPhase.ready ? stopAllBefore : stopAllBefore + 1,
      );

      // 回到一个可继续的起点
      coordinator.resourcesReady(const Duration(seconds: 12));
      await settleAsync(tester);
    }
  });

  testWidgets('音频准备失败不影响资源状态和按钮', (tester) async {
    setSurfaceSize(tester, const Size(640, 360));
    audio = FakeExamAudio()..failPrepare = true;
    coordinator = ExamCoordinator(audio: audio);
    await tester.pumpWidget(AppShell(coordinator: coordinator, audio: audio));
    await waitUntilResourcesResolved(tester, coordinator);

    expect(coordinator.resourceStatus, ResourceStatus.ready);
    expect(find.text(Copy.startScan), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
