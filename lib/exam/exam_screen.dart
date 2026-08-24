import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../resources/design_tokens.dart';
import 'exam_coordinator.dart';
import 'exam_phase.dart';
import 'widgets/ready_view.dart';
import 'widgets/result_view.dart';
import 'widgets/scanning_view.dart';

/// 检查界面：渲染三态，把动画事件上报给协调器。
///
/// 持有 Lottie 的 [AnimationController]：进入 `scanning` 时从第 0 帧播放，
/// 进入 `result` 时停在末帧，进入 `ready` 时移除并释放。启停都放在协调器
/// 状态监听回调里，不在 `build` 中。
///
/// 在 `scanning` 与 `result` 之间保留同一个 Lottie Widget（同一棵子树
/// 保持挂载），保证动画连续、无重新加载。
class ExamScreen extends StatefulWidget {
  const ExamScreen({super.key, required this.coordinator, this.composition});

  final ExamCoordinator coordinator;

  /// 预加载的 Lottie composition。资源就绪后非空；未就绪时不会进入 `scanning`。
  final LottieComposition? composition;

  /// 16:9 舞台容器，供尺寸类测试定位。
  static const stageKey = ValueKey('exam-stage');

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> with TickerProviderStateMixin {
  // 中断后控制器会被释放，新一轮扫描会重建控制器，所以需要多 ticker 支持。
  AnimationController? _animation;
  ExamPhase _lastPhase = ExamPhase.ready;
  int? _currentRunId;

  /// 局部去重标记，只为避免每一帧都向协调器重复上报虫子音效点；
  /// 「每轮一次」的业务规则由协调器的 `wormCuePlayedThisRun` 决定。
  bool _wormFiredThisRun = false;

  @override
  void initState() {
    super.initState();
    _lastPhase = widget.coordinator.phase;
    widget.coordinator.addListener(_onCoordinatorChanged);
    // 挂载时协调器可能已在 scanning/result（状态先于 Widget 存在时），
    // 下一帧补启动/定位动画，保证渲染与状态一致。
    if (_lastPhase != ExamPhase.ready) {
      final phaseAtMount = _lastPhase;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || widget.coordinator.phase != phaseAtMount) {
          return;
        }
        if (phaseAtMount == ExamPhase.scanning) {
          _beginScan();
        } else {
          _ensureAnimation();
          _animation!.stop();
          _animation!.value = 1.0;
        }
        setState(() {});
      });
    }
  }

  @override
  void dispose() {
    widget.coordinator.removeListener(_onCoordinatorChanged);
    _releaseAnimation();
    super.dispose();
  }

  void _onCoordinatorChanged() {
    final phase = widget.coordinator.phase;
    if (phase == _lastPhase) {
      return;
    }
    final previous = _lastPhase;
    _lastPhase = phase;

    if (phase == ExamPhase.scanning && previous != ExamPhase.scanning) {
      _beginScan();
    } else if (phase == ExamPhase.result && previous == ExamPhase.scanning) {
      _stopAtEndFrame();
    } else if (phase == ExamPhase.ready && previous != ExamPhase.ready) {
      _releaseAnimation();
    }
    if (mounted) {
      setState(() {});
    }
  }

  void _beginScan() {
    _currentRunId = widget.coordinator.runId;
    _wormFiredThisRun = false;
    if (widget.composition == null) {
      // 协调器在资源未就绪时不会进入 scanning，这里只是防御。
      return;
    }
    _ensureAnimation();
    _animation!.reset();
    _animation!.forward(from: 0);
  }

  void _ensureAnimation() {
    if (_animation != null) {
      return;
    }
    final controller = AnimationController(
      vsync: this,
      duration: widget.composition!.duration,
    );
    controller.addListener(_onAnimationTick);
    _animation = controller;
  }

  void _stopAtEndFrame() {
    final controller = _animation;
    if (controller == null) {
      return;
    }
    controller.stop();
    controller.value = 1.0; // 停在末帧，供结果页叠加提示板
  }

  void _releaseAnimation() {
    _currentRunId = null;
    _wormFiredThisRun = false;
    _animation?.dispose();
    _animation = null;
  }

  void _onAnimationTick() {
    if (!mounted) {
      return;
    }
    final runId = _currentRunId;
    final controller = _animation;
    if (runId == null || controller == null) {
      return;
    }
    if (controller.status == AnimationStatus.completed) {
      widget.coordinator.completeScan(runId);
    } else if (!_wormFiredThisRun &&
        controller.value >= DesignTokens.wormCueProgress) {
      _wormFiredThisRun = true;
      widget.coordinator.playWormCue(runId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final coordinator = widget.coordinator;
    final phase = coordinator.phase;

    return LayoutBuilder(
      builder: (context, constraints) {
        final stage = _stageSize(constraints.biggest);
        return ColoredBox(
          color: DesignTokens.stageOutside,
          child: Center(
            child: SizedBox(
              key: ExamScreen.stageKey,
              width: stage.width,
              height: stage.height,
              child: ClipRect(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (phase == ExamPhase.ready)
                      ReadyView(
                        resourceStatus: coordinator.resourceStatus,
                        onStartScan: coordinator.startScan,
                      )
                    else if (widget.composition != null && _animation != null)
                      ScanningView(
                        composition: widget.composition!,
                        controller: _animation!,
                      ),
                    if (phase == ExamPhase.result)
                      ResultView(onReplay: coordinator.replay),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 在可用区域里取最大的 16:9 舞台。
  Size _stageSize(Size available) {
    final widthByHeight = available.height * DesignTokens.stageAspectRatio;
    if (widthByHeight <= available.width) {
      return Size(widthByHeight, available.height);
    }
    return Size(
      available.width,
      available.width / DesignTokens.stageAspectRatio,
    );
  }
}
