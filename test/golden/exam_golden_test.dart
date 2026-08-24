import 'package:child_doctor_app/exam/exam_coordinator.dart';
import 'package:child_doctor_app/exam/exam_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../exam/fake_exam_audio.dart';
import '../exam/test_helpers.dart';

/// Golden 基线：ready、scanning 代表帧、result × 16:9 / 20:9 / 4:3。
///
/// 基线由当前检查室插画和扫描关键帧生成；正式视觉稿到位后统一更新基线。
/// 生成命令：flutter test --update-goldens test/golden
void main() {
  const sizes = <String, Size>{
    '16x9_phone': Size(640, 360),
    '20x9_phone': Size(800, 360),
    '4x3_tablet': Size(1024, 768),
  };

  Future<ExamCoordinator> pumpReady(WidgetTester tester, Size size) async {
    final audio = FakeExamAudio();
    final coordinator = ExamCoordinator(audio: audio);
    final composition = await loadScanComposition(tester);
    coordinator.resourcesReady(composition.duration);
    await pumpExamScreen(
      tester,
      coordinator: coordinator,
      composition: composition,
      size: size,
    );
    // 等背景图解码完成并渲染一帧，避免 Golden 拍到未加载的检查室。
    await settleAsync(tester);
    return coordinator;
  }

  for (final entry in sizes.entries) {
    final name = entry.key;
    final size = entry.value;

    testWidgets('ready $name', (tester) async {
      final coordinator = await pumpReady(tester, size);
      await expectLater(
        find.byType(ExamScreen),
        matchesGoldenFile('goldens/ready_$name.png'),
      );
      coordinator.abort();
      await tester.pump();
    });

    testWidgets('scanning 代表帧（虫子可见）$name', (tester) async {
      final coordinator = await pumpReady(tester, size);
      coordinator.startScan();
      await tester.pump();
      // 推进到 7.5s：进度 62.5%，虫子已出现（7.0s 出现，7.2s 完全显现）
      await tester.pump(const Duration(milliseconds: 7500));
      await expectLater(
        find.byType(ExamScreen),
        matchesGoldenFile('goldens/scanning_$name.png'),
      );
      coordinator.abort();
      await tester.pump();
    });

    testWidgets('result $name', (tester) async {
      final coordinator = await pumpReady(tester, size);
      coordinator.startScan();
      await playScanThrough(tester);
      await expectLater(
        find.byType(ExamScreen),
        matchesGoldenFile('goldens/result_$name.png'),
      );
      coordinator.abort();
      await tester.pump();
    });
  }
}
