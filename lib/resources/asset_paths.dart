/// 包内素材路径，与 `pubspec.yaml` 的 assets 声明一致。
abstract final class AssetPaths {
  static const examRoomImage = 'assets/images/exam_room.webp';
  static const scanAnimation = 'assets/lottie/scan.json';
  static const scanBedAudio = 'assets/audio/scan_loop.mp3';
  static const wormCueAudio = 'assets/audio/worm_cue.mp3';
  static const washHintAudio = 'assets/audio/wash_hint.mp3';

  /// audioplayers 的 `AssetSource` 使用 AudioCache 默认前缀 `assets/`，
  /// 这里给出去掉前缀后的相对路径。
  static String audioSource(String fullAssetPath) {
    const prefix = 'assets/';
    assert(fullAssetPath.startsWith(prefix));
    return fullAssetPath.substring(prefix.length);
  }
}
