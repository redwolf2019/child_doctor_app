# 肚子扫描仪

给小孩看的离线卡通教育演示 App。成人横着拿 Android 手机或平板，小孩点击「开始扫描」，观看约 12 秒卡通扫描，最后看到并听到固定洗手提示：「不洗手就吃东西，肚子里会长虫子。快去洗手！」

首版是可侧载的 Flutter Android APK（Android 8.0 / API 26 及以上），全部素材打进包内，没有账号、后台、网络、用户数据或医学诊断。屏幕里被扫描的是固定卡通小孩，不是正在观看的真实小孩。

产品行为、技术基线和验收要求见 [产品及技术设计文档](docs/产品及技术设计文档.md)；当前实现任务见 [docs/issues](docs/issues/)。

## 开发命令

```bash
flutter pub get
dart format --set-exit-if-changed lib test integration_test
flutter analyze
flutter test
flutter test integration_test -d <device-id>   # 真机集成测试
flutter build apk --debug
flutter build apk --release
```

Flutter 精确版本记录在 `.flutter-version`；依赖锁定在 `pubspec.lock`。
