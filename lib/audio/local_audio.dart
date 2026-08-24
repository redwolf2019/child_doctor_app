import 'package:audioplayers/audioplayers.dart';

import '../resources/asset_paths.dart';
import 'exam_audio.dart';

/// [ExamAudio] 的生产实现：三个独立 `AudioPlayer` 分别管理扫描底音、
/// 虫子音效和洗手配音，避免互相打断或叠音。
///
/// 所有操作失败时抛出异常，由调用方（`ExamCoordinator`/`AppShell`）
/// 按设计静默降级；本类不吞错误，保证错误路径可见。
class LocalAudio implements ExamAudio {
  LocalAudio({
    AudioPlayer? scanBedPlayer,
    AudioPlayer? wormCuePlayer,
    AudioPlayer? washHintPlayer,
  }) : _scanBed = scanBedPlayer ?? AudioPlayer(),
       _wormCue = wormCuePlayer ?? AudioPlayer(),
       _washHint = washHintPlayer ?? AudioPlayer();

  final AudioPlayer _scanBed;
  final AudioPlayer _wormCue;
  final AudioPlayer _washHint;

  bool _disposed = false;

  void _ensureNotDisposed() {
    if (_disposed) {
      throw StateError('LocalAudio 已 dispose');
    }
  }

  @override
  Future<void> prepare() async {
    _ensureNotDisposed();
    // 音频焦点被抢占时允许系统暂停或降低声音（duck），画面继续。
    // 焦点恢复后不会补播任何已触发的音效或配音——代码从不重放。
    await AudioPlayer.global.setAudioContext(
      AudioContext(
        android: AudioContextAndroid(
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.media,
          audioFocus: AndroidAudioFocus.gainTransientMayDuck,
        ),
      ),
    );
    await _scanBed.setSourceAsset(
      AssetPaths.audioSource(AssetPaths.scanBedAudio),
    );
    await _wormCue.setSourceAsset(
      AssetPaths.audioSource(AssetPaths.wormCueAudio),
    );
    await _washHint.setSourceAsset(
      AssetPaths.audioSource(AssetPaths.washHintAudio),
    );
  }

  @override
  Future<void> startScanBed() async {
    _ensureNotDisposed();
    await _scanBed.setReleaseMode(ReleaseMode.loop);
    await _scanBed.resume();
  }

  @override
  Future<void> stopScanBed() async {
    _ensureNotDisposed();
    await _scanBed.stop();
  }

  @override
  Future<void> playWormCue() async {
    _ensureNotDisposed();
    await _wormCue.setReleaseMode(ReleaseMode.stop);
    await _wormCue.stop(); // 回到起点，保证每次都从头播放
    await _wormCue.resume();
  }

  @override
  Future<void> playWashHint() async {
    _ensureNotDisposed();
    await _washHint.setReleaseMode(ReleaseMode.stop);
    await _washHint.stop();
    await _washHint.resume();
  }

  @override
  Future<void> stopAll() async {
    _ensureNotDisposed();
    await Future.wait([_scanBed.stop(), _wormCue.stop(), _washHint.stop()]);
  }

  @override
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    await Future.wait([
      _scanBed.dispose(),
      _wormCue.dispose(),
      _washHint.dispose(),
    ]);
  }
}
