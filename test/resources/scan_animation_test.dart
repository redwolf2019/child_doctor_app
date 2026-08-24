import 'package:child_doctor_app/resources/asset_paths.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';

// LayerType 不在公开导出中；只为断言「无文字层」。
// ignore_for_file: implementation_imports
import 'package:lottie/src/model/layer/layer.dart' show LayerType;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LottieComposition composition;

  setUpAll(() async {
    final data = await rootBundle.load(AssetPaths.scanAnimation);
    composition = await LottieComposition.fromByteData(data);
  });

  test('scan.json 可被 Flutter 解析，规格符合素材契约', () {
    // 1920x1080、30 fps、360 帧
    expect(composition.bounds.width, 1920);
    expect(composition.bounds.height, 1080);
    expect(composition.frameRate, 30);
    expect(composition.durationFrames, closeTo(360, 0.01));
  });

  test('scan.json 时长在 11.5~12.5 秒基线内', () {
    expect(composition.duration, const Duration(milliseconds: 12000));
    expect(composition.duration.inMilliseconds, inInclusiveRange(11500, 12500));
  });

  test('scan.json 不引用外部位图', () {
    expect(composition.images, isEmpty);
  });

  test('scan.json 不含文字层', () {
    for (final layer in composition.layers) {
      expect(
        layer.layerType != LayerType.text,
        isTrue,
        reason: 'scan.json 不能包含文字层，文案由 Flutter 绘制',
      );
    }
  });
}
