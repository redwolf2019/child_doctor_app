# App 锁定横屏

首版在 AndroidManifest 用 `android:screenOrientation="sensorLandscape"` 锁定 Activity 为横屏，两个横屏方向都跟随传感器。打开 App 后无需成人手动旋转设备。

这是用户明确要求的产品决定，推翻了 ADR 之前「不锁死方向、靠竖屏门禁识别设备朝向」的基线。锁屏后窗口一直是横屏尺寸，竖屏门禁实际不可达；门禁代码和测试保留为纵深防御，若将来撤销锁定，门禁仍然可用。

`SystemChrome.setPreferredOrientations` 不采用：它只在 Flutter 初始化后生效，启动瞬间仍可能出现竖屏窗口；manifest 声明从 Activity 创建起就生效。

若未来需要「竖屏时提示转横」的交互，撤销本决定，门禁即恢复工作。
