import 'package:child_doctor_app/audio/exam_audio.dart';

/// 记录调用并可模拟错误的测试替身，不加载平台播放器。
class FakeExamAudio implements ExamAudio {
  final List<String> calls = [];

  /// 各操作是否模拟抛错（同步/异步错误都由调用方兜底）。
  bool failPrepare = false;
  bool failStartScanBed = false;
  bool failStopScanBed = false;
  bool failPlayWormCue = false;
  bool failPlayWashHint = false;
  bool failStopAll = false;

  int count(String name) => calls.where((c) => c == name).length;

  Future<void> _run(String name, bool fail) async {
    calls.add(name);
    if (fail) {
      throw Exception('模拟音频错误：$name');
    }
  }

  @override
  Future<void> prepare() => _run('prepare', failPrepare);

  @override
  Future<void> startScanBed() => _run('startScanBed', failStartScanBed);

  @override
  Future<void> stopScanBed() => _run('stopScanBed', failStopScanBed);

  @override
  Future<void> playWormCue() => _run('playWormCue', failPlayWormCue);

  @override
  Future<void> playWashHint() => _run('playWashHint', failPlayWashHint);

  @override
  Future<void> stopAll() => _run('stopAll', failStopAll);

  @override
  Future<void> dispose() => _run('dispose', false);
}
