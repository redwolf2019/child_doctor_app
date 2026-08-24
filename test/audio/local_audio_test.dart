import 'dart:async';

import 'package:audioplayers_platform_interface/audioplayers_platform_interface.dart';
import 'package:child_doctor_app/audio/local_audio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// 测试替身必须继承具体平台类才能通过 PlatformInterface 的 token 校验，
// 而具体类不在公开导出中；这是 audioplayers 官方测试同款做法。
// ignore_for_file: implementation_imports
import 'package:audioplayers_platform_interface/src/audioplayers_platform.dart';
import 'package:audioplayers_platform_interface/src/global_audioplayers_platform.dart';

/// 记录调用的假平台，不经过 MethodChannel。
class FakeAudioplayersPlatform extends AudioplayersPlatform {
  final List<String> calls = [];
  final Map<String, String> sourceByPlayer = {};
  final List<String> createdPlayers = [];
  final _events = <String, StreamController<AudioEvent>>{};

  void _record(String call) => calls.add(call);

  @override
  Future<void> create(String playerId) async {
    createdPlayers.add(playerId);
    _record('create:$playerId');
  }

  @override
  Future<void> dispose(String playerId) async {
    _record('dispose:$playerId');
  }

  @override
  Future<void> release(String playerId) async {
    _record('release:$playerId');
  }

  @override
  Future<void> resume(String playerId) async {
    _record('resume:$playerId');
  }

  @override
  Future<void> pause(String playerId) async {
    _record('pause:$playerId');
  }

  @override
  Future<void> stop(String playerId) async {
    _record('stop:$playerId');
  }

  @override
  Future<void> seek(String playerId, Duration position) async {
    _record('seek:$playerId');
  }

  @override
  Future<void> setReleaseMode(String playerId, ReleaseMode releaseMode) async {
    _record('setReleaseMode:$playerId:${releaseMode.name}');
  }

  @override
  Future<void> setSourceUrl(
    String playerId,
    String url, {
    String? mimeType,
    bool? isLocal,
  }) async {
    sourceByPlayer[playerId] = url;
    _record('setSourceUrl:$playerId:$url');
    // 真实平台在源设置完成后发出 prepared 事件。
    _events[playerId]?.add(
      AudioEvent(
        eventType: AudioEventType.prepared,
        isPrepared: true,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Future<int?> getCurrentPosition(String playerId) async => null;

  @override
  Future<int?> getDuration(String playerId) async => null;

  @override
  Future<void> setAudioContext(String playerId, AudioContext ctx) async {
    _record('setAudioContext:$playerId');
  }

  @override
  Stream<AudioEvent> getEventStream(String playerId) => _events
      .putIfAbsent(playerId, () => StreamController<AudioEvent>.broadcast())
      .stream;
}

class FakeGlobalAudioplayersPlatform extends GlobalAudioplayersPlatform {
  AudioContext? audioContext;

  @override
  Future<void> init() async {}

  @override
  Future<void> setGlobalAudioContext(AudioContext ctx) async {
    audioContext = ctx;
  }

  @override
  Future<void> emitGlobalLog(String message) async {}

  @override
  Future<void> emitGlobalError(String code, String message) async {}

  @override
  Stream<GlobalAudioEvent> getGlobalEventStream() => const Stream.empty();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeAudioplayersPlatform platform;
  late FakeGlobalAudioplayersPlatform globalPlatform;
  late LocalAudio audio;

  setUp(() async {
    platform = FakeAudioplayersPlatform();
    globalPlatform = FakeGlobalAudioplayersPlatform();
    AudioplayersPlatformInterface.instance = platform;
    GlobalAudioplayersPlatformInterface.instance = globalPlatform;

    // path_provider 的临时目录由假 handler 提供，不依赖真机插件。
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async {
            if (call.method == 'getTemporaryDirectory') {
              return '/tmp/cda_audio_test';
            }
            return null;
          },
        );

    audio = LocalAudio();
  });

  tearDown(() async {
    await audio.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          null,
        );
  });

  /// 播放器的 create 顺序与构造顺序不保证一致（首次 init 的异步调度），
  /// 按源文件反查各播放器 id。
  String playerIdForAsset(String assetName) => platform.sourceByPlayer.entries
      .firstWhere((e) => e.value.contains(assetName))
      .key;

  test('prepare 配置音频焦点并加载三个本地源', () async {
    await audio.prepare();

    expect(globalPlatform.audioContext, isNotNull);
    expect(
      globalPlatform.audioContext!.android.audioFocus,
      AndroidAudioFocus.gainTransientMayDuck,
    );

    expect(platform.createdPlayers, hasLength(3));
    final sources = platform.sourceByPlayer.values.toList();
    expect(sources, hasLength(3));
    expect(sources.any((s) => s.contains('audio/scan_loop.mp3')), isTrue);
    expect(sources.any((s) => s.contains('audio/worm_cue.mp3')), isTrue);
    expect(sources.any((s) => s.contains('audio/wash_hint.mp3')), isTrue);
  });

  test('startScanBed/stopScanBed 只操作底音播放器并设循环', () async {
    await audio.prepare();
    final bedId = playerIdForAsset('scan_loop.mp3');

    await audio.startScanBed();
    expect(platform.calls, contains('setReleaseMode:$bedId:loop'));
    expect(platform.calls, contains('resume:$bedId'));

    await audio.stopScanBed();
    expect(platform.calls, contains('stop:$bedId'));
  });

  test('playWormCue 从起点播放一次虫子音效', () async {
    await audio.prepare();
    final wormId = playerIdForAsset('worm_cue.mp3');

    await audio.playWormCue();
    expect(platform.calls, contains('setReleaseMode:$wormId:stop'));
    expect(platform.calls, contains('stop:$wormId'));
    expect(platform.calls, contains('resume:$wormId'));
  });

  test('playWashHint 从起点播放一次配音', () async {
    await audio.prepare();
    final voiceId = playerIdForAsset('wash_hint.mp3');

    await audio.playWashHint();
    expect(platform.calls, contains('setReleaseMode:$voiceId:stop'));
    expect(platform.calls, contains('resume:$voiceId'));
  });

  test('stopAll 停止三个播放器，可重复调用', () async {
    await audio.prepare();
    final ids = platform.createdPlayers.toSet();

    await audio.stopAll();
    await audio.stopAll();
    final stopCount = platform.calls.where((c) => c.startsWith('stop:')).length;
    expect(stopCount, 6); // 三个播放器 × 两次
    for (final id in ids) {
      expect(platform.calls, contains('stop:$id'));
    }
  });

  test('dispose 释放三个播放器，可重复调用', () async {
    await audio.prepare();
    final ids = platform.createdPlayers.toSet();

    await audio.dispose();
    await audio.dispose();
    for (final id in ids) {
      expect(platform.calls, contains('release:$id'));
    }
    final releaseCount = platform.calls
        .where((c) => c.startsWith('release:'))
        .length;
    expect(releaseCount, 3); // 第二次 dispose 是空操作
  });
}
