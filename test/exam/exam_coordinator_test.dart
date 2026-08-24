import 'dart:ui' show AppLifecycleState;

import 'package:child_doctor_app/exam/exam_coordinator.dart';
import 'package:child_doctor_app/exam/exam_phase.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_exam_audio.dart';

void main() {
  late FakeExamAudio audio;
  late ExamCoordinator coordinator;

  setUp(() {
    audio = FakeExamAudio();
    coordinator = ExamCoordinator(audio: audio);
  });

  tearDown(() => coordinator.dispose());

  group('初始与资源状态', () {
    test('U01 初始状态：ready + loading，无活动 watchdog', () {
      expect(coordinator.phase, ExamPhase.ready);
      expect(coordinator.resourceStatus, ResourceStatus.loading);
      fakeAsync((async) {
        async.elapse(const Duration(minutes: 5));
        expect(coordinator.phase, ExamPhase.ready);
      });
    });

    test('U02 资源加载成功：保存时长、变 ready、可开始扫描', () {
      coordinator.resourcesReady(const Duration(milliseconds: 12000));
      expect(coordinator.resourceStatus, ResourceStatus.ready);
      expect(coordinator.scanDuration, const Duration(milliseconds: 12000));

      coordinator.startScan();
      expect(coordinator.phase, ExamPhase.scanning);
    });

    test('U03 资源加载失败：变 failed，startScan 无状态和音频变化', () {
      coordinator.resourcesFailed();
      expect(coordinator.resourceStatus, ResourceStatus.failed);

      coordinator.startScan();
      expect(coordinator.phase, ExamPhase.ready);
      expect(coordinator.runId, 0);
      expect(audio.calls, isEmpty);
    });

    test('资源事件只在 loading 时生效一次', () {
      coordinator.resourcesReady(const Duration(seconds: 12));
      coordinator.resourcesReady(const Duration(seconds: 13));
      expect(coordinator.scanDuration, const Duration(seconds: 12));

      coordinator.resourcesFailed();
      expect(coordinator.resourceStatus, ResourceStatus.ready);
    });
  });

  group('扫描与完成', () {
    setUp(() => coordinator.resourcesReady(const Duration(seconds: 12)));

    test('U04 合法开始：ready→scanning，runId+1，底音一次', () {
      coordinator.startScan();
      expect(coordinator.phase, ExamPhase.scanning);
      expect(coordinator.runId, 1);
      expect(audio.count('startScanBed'), 1);
    });

    test('U05 连续开始 5 次：只有第一次有效', () {
      for (var i = 0; i < 5; i++) {
        coordinator.startScan();
      }
      expect(coordinator.phase, ExamPhase.scanning);
      expect(coordinator.runId, 1);
      expect(audio.count('startScanBed'), 1);
    });

    test('U06 虫子进度重复回调：同一 runId 只播一次虫子音效', () {
      coordinator.startScan();
      final runId = coordinator.runId;
      coordinator.playWormCue(runId);
      coordinator.playWormCue(runId);
      coordinator.playWormCue(runId);
      expect(audio.count('playWormCue'), 1);
      expect(coordinator.wormCuePlayedThisRun, isTrue);
    });

    test('U07 正常完成：停底音、取消 watchdog、进 result、配音一次', () {
      coordinator.startScan();
      final runId = coordinator.runId;
      coordinator.completeScan(runId);

      expect(coordinator.phase, ExamPhase.result);
      expect(coordinator.watchdogTriggered, isFalse);
      expect(audio.count('stopScanBed'), 1);
      expect(audio.count('playWashHint'), 1);

      // watchdog 已取消：时间流逝不再产生状态变化
      fakeAsync((async) {
        async.elapse(const Duration(minutes: 5));
      });
      expect(coordinator.phase, ExamPhase.result);
      expect(audio.count('playWashHint'), 1);
    });

    test('U08 watchdog：duration+999ms 不触发，再过 1ms 进 result', () {
      fakeAsync((async) {
        coordinator.resourcesReady(const Duration(seconds: 12));
        coordinator.startScan();

        async.elapse(const Duration(seconds: 12, milliseconds: 999));
        expect(coordinator.phase, ExamPhase.scanning);

        async.elapse(const Duration(milliseconds: 1));
        expect(coordinator.phase, ExamPhase.result);
        expect(coordinator.watchdogTriggered, isTrue);
        expect(audio.count('stopScanBed'), 1);
        // 兜底路径同样播放一次洗手配音（AGENTS.md 产品边界）。
        expect(audio.count('playWashHint'), 1);
      });
    });

    test('U09 正常完成后 watchdog 晚到：状态和音频不再变化', () {
      fakeAsync((async) {
        coordinator.resourcesReady(const Duration(seconds: 12));
        coordinator.startScan();
        coordinator.completeScan(coordinator.runId);
        expect(coordinator.phase, ExamPhase.result);

        final washCount = audio.count('playWashHint');
        async.elapse(const Duration(seconds: 20));
        expect(coordinator.phase, ExamPhase.result);
        expect(audio.count('playWashHint'), washCount);
        expect(audio.count('stopScanBed'), 1);
      });
    });

    test('U10 replay：停配音、result→scanning、新 runId、虫子标记重置', () {
      coordinator.startScan();
      final firstRunId = coordinator.runId;
      coordinator.playWormCue(firstRunId);
      coordinator.completeScan(firstRunId);
      expect(audio.count('playWashHint'), 1);

      coordinator.replay();
      expect(coordinator.phase, ExamPhase.scanning);
      expect(coordinator.runId, firstRunId + 1);
      expect(audio.count('stopAll'), 1); // 停掉洗手配音
      expect(coordinator.wormCuePlayedThisRun, isFalse);

      coordinator.playWormCue(coordinator.runId);
      expect(audio.count('playWormCue'), 2);
    });

    test('U11 上一轮完成回调晚到：旧 runId 被丢弃，不提前结束新一轮', () {
      coordinator.startScan();
      final firstRunId = coordinator.runId;
      coordinator.completeScan(firstRunId);
      coordinator.replay();
      final secondRunId = coordinator.runId;

      coordinator.completeScan(firstRunId);
      expect(coordinator.phase, ExamPhase.scanning);
      expect(audio.count('stopScanBed'), 1); // 仍只有第一轮的那次
      expect(audio.count('playWashHint'), 1);

      // 新一轮正常完成
      coordinator.completeScan(secondRunId);
      expect(coordinator.phase, ExamPhase.result);
    });

    test('completeScan/playWormCue 在错误状态下被忽略', () {
      coordinator.completeScan(0); // 未开始扫描
      expect(coordinator.phase, ExamPhase.ready);
      expect(audio.calls, isEmpty);

      coordinator.playWormCue(999);
      expect(audio.count('playWormCue'), 0);
    });
  });

  group('中断与生命周期', () {
    setUp(() => coordinator.resourcesReady(const Duration(seconds: 12)));

    test('U12 abort：任意状态回 ready，timer 取消，stopAll 一次', () {
      fakeAsync((async) {
        coordinator.startScan();
        coordinator.abort();

        expect(coordinator.phase, ExamPhase.ready);
        expect(audio.count('stopAll'), 1);

        // watchdog 已取消：时间流逝不产生结果
        async.elapse(const Duration(minutes: 5));
        expect(coordinator.phase, ExamPhase.ready);
        expect(audio.count('playWashHint'), 0);
      });
    });

    test('U13 重复 abort/dispose：不抛异常，不重复产生业务通知', () {
      var notifications = 0;
      coordinator.addListener(() => notifications++);

      coordinator.startScan();
      coordinator.abort();
      final afterFirstAbort = notifications;
      coordinator.abort();
      coordinator.abort();
      expect(coordinator.phase, ExamPhase.ready);
      expect(notifications, afterFirstAbort); // 无新状态变化
      coordinator.dispose();
      coordinator.dispose();
      coordinator.abort();
    });

    test('abort 后旧 runId 回调被丢弃', () {
      coordinator.startScan();
      final oldRunId = coordinator.runId;
      coordinator.abort();

      coordinator.completeScan(oldRunId);
      coordinator.playWormCue(oldRunId);
      expect(coordinator.phase, ExamPhase.ready);
      expect(audio.count('playWashHint'), 0);
      expect(audio.count('playWormCue'), 0);
    });

    test('U14 inactive：不迁移当前状态，拒绝新 startScan/replay', () {
      coordinator.onAppLifecycle(AppLifecycleState.inactive);

      coordinator.startScan();
      expect(coordinator.phase, ExamPhase.ready);
      expect(coordinator.runId, 0);
      expect(audio.calls, isEmpty);

      // 先到 result，再验证 inactive 拒绝 replay
      coordinator.onAppLifecycle(AppLifecycleState.resumed);
      coordinator.startScan();
      coordinator.completeScan(coordinator.runId);
      expect(coordinator.phase, ExamPhase.result);

      coordinator.onAppLifecycle(AppLifecycleState.inactive);
      coordinator.replay();
      expect(coordinator.phase, ExamPhase.result);
      expect(coordinator.runId, 1);
    });

    test('U15 paused/hidden：执行 abort，恢复后是 ready 且可再次开始', () {
      coordinator.startScan();
      coordinator.onAppLifecycle(AppLifecycleState.paused);
      expect(coordinator.phase, ExamPhase.ready);
      expect(audio.count('stopAll'), 1);

      coordinator.onAppLifecycle(AppLifecycleState.resumed);
      coordinator.startScan();
      expect(coordinator.phase, ExamPhase.scanning);

      coordinator.onAppLifecycle(AppLifecycleState.hidden);
      expect(coordinator.phase, ExamPhase.ready);
    });

    test('U16 音频 adapter 抛错：状态机继续，无未处理异常，结果可达', () {
      audio.failStartScanBed = true;
      audio.failStopScanBed = true;
      audio.failPlayWashHint = true;
      audio.failPlayWormCue = true;
      audio.failStopAll = true;

      coordinator.startScan();
      expect(coordinator.phase, ExamPhase.scanning);

      coordinator.playWormCue(coordinator.runId);
      expect(coordinator.wormCuePlayedThisRun, isTrue);

      coordinator.completeScan(coordinator.runId);
      expect(coordinator.phase, ExamPhase.result);

      coordinator.abort();
      expect(coordinator.phase, ExamPhase.ready);
    });
  });
}
