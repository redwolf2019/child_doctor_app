import 'package:child_doctor_app/exam/orientation_gate.dart';
import 'package:child_doctor_app/exam/widgets/rotate_hint_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<List<bool>> pumpGate(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final calls = <bool>[];
    await tester.pumpWidget(
      MaterialApp(
        home: OrientationGate(
          onOrientationChanged: calls.add,
          child: const ColoredBox(color: Colors.red, child: Text('业务内容')),
        ),
      ),
    );
    return calls;
  }

  void resize(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
  }

  testWidgets('竖屏只显示转横提示，横屏显示业务 child', (tester) async {
    final calls = await pumpGate(tester, const Size(600, 800));
    await tester.pump();

    expect(find.byType(RotateHintView), findsOneWidget);
    expect(find.text('业务内容'), findsNothing);
    expect(calls, isEmpty); // 初始方向不是「变化」，不发事件

    resize(tester, const Size(800, 360));
    await tester.pump();
    expect(find.byType(RotateHintView), findsNothing);
    expect(find.text('业务内容'), findsOneWidget);
    expect(calls, [true]);
  });

  testWidgets('方向只在横竖真正切换时回调一次，尺寸变化去重', (tester) async {
    final calls = await pumpGate(tester, const Size(800, 360));

    // 横屏内改变尺寸：不回调
    resize(tester, const Size(960, 360));
    await tester.pump();
    resize(tester, const Size(1024, 600));
    await tester.pump();
    expect(calls, isEmpty);

    // 横 → 竖：一次回调
    resize(tester, const Size(360, 800));
    await tester.pump();
    expect(calls, [false]);

    // 竖屏内改变尺寸：不回调
    resize(tester, const Size(400, 800));
    await tester.pump();
    expect(calls, [false]);

    // 竖 → 横：一次回调
    resize(tester, const Size(800, 360));
    await tester.pump();
    expect(calls, [false, true]);
  });

  testWidgets('宽高相等按横屏处理（门禁只在高度严格大于宽度时显示）', (tester) async {
    final calls = await pumpGate(tester, const Size(600, 600));
    await tester.pump();
    // 规格：`height > width` 才显示竖屏门禁，相等时显示业务内容。
    expect(find.byType(RotateHintView), findsNothing);
    expect(find.text('业务内容'), findsOneWidget);
    expect(calls, isEmpty);

    resize(tester, const Size(600, 700));
    await tester.pump();
    expect(find.byType(RotateHintView), findsOneWidget);
    expect(calls, [false]);
  });
}
