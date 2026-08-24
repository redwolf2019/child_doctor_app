/// 固定文案。界面文字、配音脚本、常量和测试必须一致，业务 Widget 不复制字符串。
///
/// 变更 `washHint` 时同步核对配音脚本、测试和 [CONTEXT.md](../../CONTEXT.md)。
abstract final class Copy {
  static const rotateHint = '请把设备横过来';
  static const preparing = '正在准备…';
  static const startScan = '开始扫描';
  static const washHint = '不洗手就吃东西，肚子里会长虫子。快去洗手！';
  static const replay = '再看一次';
  static const loadFailed = '加载失败，请重新打开应用';
}
