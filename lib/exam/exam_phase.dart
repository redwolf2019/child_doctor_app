/// 业务状态：一次检查走到了哪里。
///
/// 方向、资源和生命周期是环境状态，不得加入 [ExamPhase]。
enum ExamPhase { ready, scanning, result }

/// 必需的 Lottie 资源是否可用。音频准备或播放失败不改变它。
enum ResourceStatus { loading, ready, failed }
