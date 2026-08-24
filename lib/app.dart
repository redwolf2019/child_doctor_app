import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';

import 'audio/exam_audio.dart';
import 'exam/exam_coordinator.dart';
import 'exam/exam_phase.dart';
import 'exam/exam_screen.dart';
import 'exam/orientation_gate.dart';
import 'resources/asset_paths.dart';
import 'resources/design_tokens.dart';

/// Flutter 根 Widget：主题、沉浸式显示、单路由、生命周期和根级返回处理。
///
/// 启动后异步预加载 Lottie composition 并准备本地音频，不阻塞第一帧：
/// 成人先看到检查室和「正在准备…」，素材就绪后原位显示按钮。
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.coordinator, required this.audio});

  final ExamCoordinator coordinator;
  final ExamAudio audio;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  LottieComposition? _composition;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _prepareAudio();
    _loadComposition();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(widget.audio.dispose());
    widget.coordinator.dispose();
    super.dispose();
  }

  /// 音频准备失败按设计静默降级：不改变资源状态，不阻止扫描和文字结果。
  Future<void> _prepareAudio() async {
    try {
      await widget.audio.prepare();
    } catch (error) {
      debugPrint('[exam] 音频准备失败（按设计静默降级）: $error');
    }
  }

  /// Lottie 预加载：成功才允许开始扫描；失败进入资源错误状态。
  Future<void> _loadComposition() async {
    try {
      final composition = await AssetLottie(AssetPaths.scanAnimation).load();
      if (!mounted) {
        return;
      }
      setState(() => _composition = composition);
      widget.coordinator.resourcesReady(composition.duration);
    } catch (error) {
      if (!mounted) {
        return;
      }
      debugPrint('[exam] Lottie 加载失败: $error');
      widget.coordinator.resourcesFailed();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    widget.coordinator.onAppLifecycle(state);
    if (state == AppLifecycleState.resumed) {
      // 进入前台时重新应用沉浸式显示。
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: DesignTokens.primaryButton,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: DesignTokens.stageOutside,
      ),
      home: PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, Object? result) {
          if (didPop) {
            return;
          }
          // 先停全部副作用，再关闭 Activity；不承诺杀死进程。
          widget.coordinator.abort();
          SystemNavigator.pop();
        },
        child: SafeArea(
          child: OrientationGate(
            onOrientationChanged: (isLandscape) {
              // 进入竖屏时如果不在检查室，执行中断；再次横屏显示检查室。
              if (!isLandscape && widget.coordinator.phase != ExamPhase.ready) {
                widget.coordinator.abort();
              }
            },
            child: ExamScreen(
              coordinator: widget.coordinator,
              composition: _composition,
            ),
          ),
        ),
      ),
    );
  }
}
