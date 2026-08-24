import 'package:child_doctor_app/app.dart';
import 'package:child_doctor_app/exam/exam_coordinator.dart';
import 'package:child_doctor_app/exam/exam_phase.dart';
import 'package:child_doctor_app/exam/exam_screen.dart';
import 'package:child_doctor_app/exam/widgets/ready_view.dart';
import 'package:child_doctor_app/exam/widgets/rotate_hint_view.dart';
import 'package:child_doctor_app/resources/copy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';

import 'fake_exam_audio.dart';
import 'test_helpers.dart';

void main() {
  group('W01 竖屏门禁', () {
    testWidgets('竖屏启动：只有转横提示，无检查室按钮，语义正确', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpApp(
        tester,
        size: const Size(600, 800),
        waitForResources: false,
      );

      expect(find.byType(RotateHintView), findsOneWidget);
      expect(find.text(Copy.startScan), findsNothing);
      expect(find.text(Copy.rotateHint), findsOneWidget);
      expect(find.bySemanticsLabel(Copy.rotateHint), findsOneWidget);
      handle.dispose();
    });

    testWidgets('转横后自动进入检查室', (tester) async {
      tester.view.physicalSize = const Size(600, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final audio = FakeExamAudio();
      final coordinator = ExamCoordinator(audio: audio);
      await tester.pumpWidget(AppShell(coordinator: coordinator, audio: audio));
      await settleAsync(tester);
      expect(find.byType(RotateHintView), findsOneWidget);

      tester.view.physicalSize = const Size(800, 360);
      await tester.pump();
      await settleAsync(tester);

      expect(find.byType(RotateHintView), findsNothing);
      expect(find.text(Copy.startScan), findsOneWidget);
    });
  });

  group('W02-W04 检查室', () {
    testWidgets('W02 横屏 loading：检查室和正在准备可见，没有可点主按钮', (tester) async {
      // 资源加载中的协调器：直接验证 ReadyView 的 loading 分支。
      final coordinator = ExamCoordinator(audio: FakeExamAudio());
      await pumpExamScreen(tester, coordinator: coordinator);

      expect(find.text(Copy.preparing), findsOneWidget);
      expect(find.text(Copy.startScan), findsNothing);
      expect(find.byType(FilledButton), findsNothing);
      // 检查室背景图可见
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('W03 横屏 ready：只有开始扫描主按钮', (tester) async {
      await pumpApp(tester, size: const Size(640, 360));

      expect(find.text(Copy.startScan), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
      expect(find.text(Copy.preparing), findsNothing);
    });

    testWidgets('W04 资源失败：固定失败文案可见，没有失效按钮', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReadyView(
              resourceStatus: ResourceStatus.failed,
              onStartScan: () {},
            ),
          ),
        ),
      );

      expect(find.text(Copy.loadFailed), findsOneWidget);
      expect(find.byType(FilledButton), findsNothing);
    });
  });

  group('W05-W06 扫描和结果', () {
    Future<ExamCoordinator> pumpScanning(
      WidgetTester tester, {
      Size size = const Size(640, 360),
    }) async {
      final audio = FakeExamAudio();
      final coordinator = ExamCoordinator(audio: audio);
      addTearDown(coordinator.dispose); // 未完成扫描时取消 watchdog，避免悬挂计时器
      final composition = await loadScanComposition(tester);
      coordinator.resourcesReady(composition.duration);
      coordinator.startScan();
      await pumpExamScreen(
        tester,
        coordinator: coordinator,
        composition: composition,
        size: size,
      );
      return coordinator;
    }

    testWidgets('W05 scanning：Lottie 可见，无按钮，点击不改变状态，虫子音效一次', (tester) async {
      final audio = FakeExamAudio();
      final coordinator = ExamCoordinator(audio: audio);
      final composition = await loadScanComposition(tester);
      coordinator.resourcesReady(composition.duration);
      coordinator.startScan();
      await pumpExamScreen(
        tester,
        coordinator: coordinator,
        composition: composition,
      );
      await tester.pump();

      expect(find.byType(Lottie), findsOneWidget);
      expect(find.byType(FilledButton), findsNothing);

      // 点击、双击和长按都没有业务效果
      final center = tester.getCenter(find.byType(ExamScreen));
      await tester.tapAt(center);
      await tester.pump();
      await tester.tapAt(center);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tapAt(center);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.longPressAt(center);
      await tester.pump();
      expect(coordinator.phase, ExamPhase.scanning);
      expect(audio.count('startScanBed'), 1);
      expect(audio.count('playWormCue'), 0);

      // 动画进度越过 58%：虫子音效一次
      await tester.pump(const Duration(seconds: 6));
      await tester.pump(const Duration(seconds: 2));
      expect(audio.count('playWormCue'), 1);
      expect(coordinator.phase, ExamPhase.scanning);

      coordinator.abort(); // 结束本轮，取消 watchdog 计时器
      await tester.pump();
    });

    testWidgets('W06 result：末帧仍在，提示板、完整洗手文案和再看一次可见', (tester) async {
      final coordinator = await pumpScanning(tester);

      await playScanThrough(tester);

      expect(coordinator.phase, ExamPhase.result);
      expect(coordinator.watchdogTriggered, isFalse); // 走正常完成路径
      expect(find.byType(Lottie), findsOneWidget); // 末帧仍在
      expect(find.text(Copy.washHint), findsOneWidget);
      expect(find.text(Copy.replay), findsOneWidget);

      // 再看一次：从第 0 帧开始新一轮
      await tester.tap(find.text(Copy.replay));
      await tester.pump();
      expect(coordinator.phase, ExamPhase.scanning);
      expect(coordinator.runId, 2);
      expect(find.text(Copy.washHint), findsNothing);

      coordinator.abort(); // 结束本轮，取消 watchdog 计时器
      await tester.pump();
    });

    testWidgets('result 提示板宽度不超过舞台 75%', (tester) async {
      final coordinator = await pumpScanning(tester);
      await playScanThrough(tester);

      final stage = tester.getSize(find.byKey(ExamScreen.stageKey));
      final panel = find.ancestor(
        of: find.text(Copy.washHint),
        matching: find.byType(Container),
      );
      final panelSize = tester.getSize(panel.first);
      expect(panelSize.width, lessThanOrEqualTo(stage.width * 0.75 + 0.1));

      coordinator.abort();
      await tester.pump();
    });
  });

  group('W07 字体 1.3 倍', () {
    testWidgets('ready + result 固定文案和按钮无溢出', (tester) async {
      setTextScale(tester, 1.3);
      await pumpApp(tester, size: const Size(640, 360));

      expect(tester.takeException(), isNull);
      expect(find.text(Copy.startScan), findsOneWidget);

      await tester.tap(find.text(Copy.startScan));
      await playScanThrough(tester);

      expect(find.text(Copy.washHint), findsOneWidget);
      expect(find.text(Copy.replay), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('W08-W10 基线尺寸', () {
    Rect stageRect(WidgetTester tester) =>
        tester.getRect(find.byKey(ExamScreen.stageKey));

    testWidgets('W08 640x360：16:9 舞台铺满可用区，不碰安全区', (tester) async {
      tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
      addTearDown(tester.view.resetPadding);
      await pumpApp(tester, size: const Size(640, 360));

      final rect = stageRect(tester);
      // 可用区 640x312，16:9 舞台按高度铺满：312 * 16/9 ≈ 554.67
      expect(rect.height, 360 - 48);
      expect(rect.width, moreOrLessEquals((360 - 48) * 16 / 9, epsilon: 0.01));
      expect(rect.top, 24); // 不进入顶部安全区
      expect(find.text(Copy.startScan), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('W09 800x360：左右留边 80，场景不拉伸', (tester) async {
      await pumpApp(tester, size: const Size(800, 360));

      final rect = stageRect(tester);
      expect(rect, const Rect.fromLTWH(80, 0, 640, 360));
      // 背景图按 contain 铺入舞台，不裁切不拉伸
      final image = tester.widget<Image>(find.byType(Image));
      expect(image.fit, BoxFit.contain);
      expect(tester.takeException(), isNull);
    });

    testWidgets('W10 960x600 与 1024x768：上下留边，舞台居中，结果布局稳定', (tester) async {
      await pumpApp(tester, size: const Size(960, 600));
      expect(
        stageRect(tester),
        const Rect.fromLTWH(0, 30, 960, 540).inflate(0),
      );

      // 4:3 平板：1024x576 舞台，上下各留 96
      await tester.pumpWidget(const SizedBox()); // 卸载旧树
      await pumpApp(tester, size: const Size(1024, 768));
      expect(stageRect(tester), const Rect.fromLTWH(0, 96, 1024, 576));

      await tester.tap(find.text(Copy.startScan));
      await playScanThrough(tester);

      expect(find.text(Copy.washHint), findsOneWidget);
      expect(find.text(Copy.replay), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
