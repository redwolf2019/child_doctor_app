import 'dart:async';
import 'dart:ui' show AppLifecycleState;

import 'package:flutter/foundation.dart';

import '../audio/exam_audio.dart';
import 'exam_phase.dart';

/// 检查状态和副作用的唯一写入口。
///
/// 持有业务状态 [phase]、资源状态 [resourceStatus]、递增的 [runId]、
/// watchdog 计时器，并编排音频。Widget 只渲染只读状态，把用户、动画和
/// 生命周期事件转发进来。
///
/// 约定：
/// - 状态先改、副作用后做：重复点击因前置条件不满足而被忽略。
/// - 所有延迟回调（动画完成、虫子音效、watchdog）都携带创建时的 [runId]，
///   回调到达时 runId 已变化或状态不匹配就丢弃。
/// - 音频失败按设计静默降级：捕获并写调试日志，不改变状态，不弹技术错误。
/// - 横屏前置条件由 `OrientationGate`/`AppShell` 保证（竖屏不渲染业务入口），
///   协调器不复制方向状态。
class ExamCoordinator extends ChangeNotifier {
  ExamCoordinator({required this._audio});

  final ExamAudio _audio;

  ExamPhase _phase = ExamPhase.ready;
  ResourceStatus _resourceStatus = ResourceStatus.loading;
  int _runId = 0;
  bool _wormCuePlayedThisRun = false;
  Duration? _scanDuration;
  Timer? _watchdog;
  bool _watchdogTriggered = false;
  bool _isAppActive = true;

  ExamPhase get phase => _phase;
  ResourceStatus get resourceStatus => _resourceStatus;

  /// 本轮扫描标识。动画、音效和计时回调都携带它，用于丢弃上一轮的迟到回调。
  int get runId => _runId;

  /// 本轮虫子音效是否已触发。每轮扫描只允许一次。
  bool get wormCuePlayedThisRun => _wormCuePlayedThisRun;

  /// 动画实际时长，由 [resourcesReady] 保存；watchdog 使用它，不写死秒数。
  Duration? get scanDuration => _scanDuration;

  /// 只有 `resumed` 且未中断时接受新的 `startScan`/`replay`。
  bool get isAppActive => _isAppActive;

  /// watchdog 是否触发过（诊断用途；测试和正式素材中出现算缺陷）。
  bool get watchdogTriggered => _watchdogTriggered;

  /// Lottie composition 加载成功。保存动画实际时长，资源变为 ready。
  void resourcesReady(Duration duration) {
    if (_resourceStatus != ResourceStatus.loading) {
      return;
    }
    _scanDuration = duration;
    _resourceStatus = ResourceStatus.ready;
    notifyListeners();
  }

  /// Lottie composition 加载失败。禁用扫描入口。
  void resourcesFailed() {
    if (_resourceStatus != ResourceStatus.loading) {
      return;
    }
    _resourceStatus = ResourceStatus.failed;
    notifyListeners();
  }

  /// 开始一轮扫描。前置条件：`ready`、资源就绪、App 在前台。
  void startScan() {
    if (_phase != ExamPhase.ready ||
        _resourceStatus != ResourceStatus.ready ||
        !_isAppActive) {
      return;
    }
    _beginScan();
  }

  /// 从结果页再来一轮。前置条件：`result`、资源就绪、App 在前台。
  void replay() {
    if (_phase != ExamPhase.result ||
        _resourceStatus != ResourceStatus.ready ||
        !_isAppActive) {
      return;
    }
    // 先停配音（stopAll 可重复调用，底音此时已停）。
    _runSafely('stopAll(replay)', _audio.stopAll);

    _beginScan();
  }

  void _beginScan() {
    // 状态先改、副作用后做。
    _phase = ExamPhase.scanning;
    _runId++;
    _wormCuePlayedThisRun = false;
    notifyListeners();

    _runSafely('startScanBed', _audio.startScanBed);

    // watchdog 是卡死兜底，不是正常结束条件；正常结束走 Lottie 完成回调。
    final duration = _scanDuration;
    if (duration == null) {
      debugPrint('[exam] 资源时长缺失，跳过 watchdog（不应发生）');
      return;
    }
    _watchdog?.cancel();
    _watchdog = Timer(duration + const Duration(milliseconds: 1000), () {
      _handleWatchdog(_runId);
    });
  }

  /// 动画正常结束。前置条件：`scanning` 且 [runId] 匹配。
  void completeScan(int runId) {
    if (_phase != ExamPhase.scanning || runId != _runId) {
      return;
    }
    _watchdog?.cancel();
    _watchdog = null;

    _phase = ExamPhase.result;
    notifyListeners();

    // 进入结果前先停止扫描底音，再播放配音。
    _runSafely('stopScanBed', _audio.stopScanBed);
    _runSafely('playWashHint', _audio.playWashHint);
  }

  /// 动画进度首次达到虫子音效点。同一轮只播放一次。
  void playWormCue(int runId) {
    if (_phase != ExamPhase.scanning ||
        runId != _runId ||
        _wormCuePlayedThisRun) {
      return;
    }
    _wormCuePlayedThisRun = true;
    _runSafely('playWormCue', _audio.playWormCue);
  }

  /// 中断当前检查：使当前 [runId] 失效、取消 watchdog、停全部音频、回 `ready`。
  /// 可重复调用；已在 `ready` 时是无副作用空操作。
  void abort() {
    if (_phase == ExamPhase.ready && _watchdog == null) {
      return;
    }
    _watchdog?.cancel();
    _watchdog = null;
    _runId++;
    _wormCuePlayedThisRun = false;

    _phase = ExamPhase.ready;
    notifyListeners();

    _runSafely('stopAll', _audio.stopAll);
  }

  /// App 生命周期输入（环境状态，不进 [ExamPhase]）。
  ///
  /// `inactive` 不迁移状态，但不接受新的开始事件；`paused`/`hidden` 执行
  /// [abort]；`resumed` 重新放行（重设沉浸式显示由 `AppShell` 负责）。
  void onAppLifecycle(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _isAppActive = true;
      case AppLifecycleState.inactive:
        _isAppActive = false;
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        _isAppActive = false;
        abort();
      case AppLifecycleState.detached:
        break;
    }
  }

  void _handleWatchdog(int runId) {
    if (_phase != ExamPhase.scanning || runId != _runId) {
      return;
    }
    _watchdog = null;
    _watchdogTriggered = true;
    debugPrint('[exam] watchdog 触发：动画超时，兜底进入结果（测试或正式素材中出现算缺陷）');
    _runSafely('stopScanBed', _audio.stopScanBed);
    _phase = ExamPhase.result;
    notifyListeners();
    // 产品边界要求动画结束后必须播放洗手提示；兜底路径同样播放一次配音。
    _runSafely('playWashHint', _audio.playWashHint);
  }

  /// 音频失败静默降级：捕获同步和异步错误，写本地调试日志，不改变状态。
  void _runSafely(String operation, Future<void> Function() call) {
    Future<void> future;
    try {
      future = call();
    } catch (error) {
      debugPrint('[exam] 音频 $operation 失败（按设计静默降级）: $error');
      return;
    }
    unawaited(
      future.catchError((Object error, StackTrace stackTrace) {
        debugPrint('[exam] 音频 $operation 失败（按设计静默降级）: $error');
      }),
    );
  }

  bool _disposed = false;

  @override
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _watchdog?.cancel();
    _watchdog = null;
    super.dispose();
  }
}
