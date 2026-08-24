# [Feature][P0] 实现首版「肚子扫描仪」Flutter Android APK

> 建议 Labels：`feature`、`P0`、`flutter`、`android`<br>
> 建议 Milestone：`MVP`<br>
> 当前状态：`Ready for Device QA`<br>
> 完成流转：`Ready for Agent` → `In Progress` → `Ready for Device QA` → `Done`

## 目标

从当前只有文档的仓库初始化 Flutter Android 工程，实现首版「肚子扫描仪」，补齐自动化测试并产出可安装 APK。代码和自动化检查全部完成后再做真机验收；没有真机结果时，状态只能到 `Ready for Device QA`，不能关闭 Issue。

App 是一段离线卡通教育演示。成人横着拿 Android 手机或平板，小孩点击「开始扫描」，观看约 12 秒扫描，最后看到并听到固定洗手提示。结果页可以直接「再看一次」。屏幕里被扫描的是固定卡通小孩，不是正在观看的真实小孩，也不是医学诊断。

## Agent 执行契约

开始前完整阅读以下文件，优先级从高到低：

1. 根目录 `AGENTS.md`
2. `CONTEXT.md`
3. `docs/产品及技术设计文档.md`
4. `docs/adr/0001-flutter-android-apk-only.md`
5. `docs/adr/0002-lottie-for-scan.md`
6. Flutter 工程初始化后的代码、配置、测试和锁文件

执行时遵守以下规则：

- 先检查仓库、Flutter SDK、Android SDK 和已连接设备，再修改文件。
- 使用当前环境中已经安装的 Flutter stable。记录完整 `flutter --version` 输出，并把精确 Flutter 版本写入仓库的工具链版本文件；不要凭记忆填写版本号。
- 依赖版本按该 Flutter 版本的兼容范围选择，必须锁定并提交 `pubspec.lock`。
- 正式素材、正式 `applicationId`、正式签名和目标真机未提供时，继续完成代码和自动化测试，不得停在脚手架阶段。
- 缺少正式素材时，生成或提交可合法分发的同名占位素材。不得从网络复制来源不明的图片、动画或音频。
- 占位素材只能用于开发和自动化测试，不能勾选正式素材、内容、音画或最终产品验收项。
- 不自行扩大产品范围。需要账号、网络、相机、设置页、iOS 或商店分发时停止并请求确认。
- 不用 TODO、FIXME、跳过测试或放宽断言代替本 Issue 要求。
- 先完成代码、自审和自动化检查，再执行真机验收。真机验收失败时回到代码修复，修复后重跑自动化检查和受影响的全部真机用例。

## 当前仓库状态

[已验证] 当前仓库只有设计文档和仓库约定，没有 `pubspec.yaml`、`lib/`、`android/`、`test/`、`integration_test/` 或 Flutter 锁文件。

| 项目 | 当前状态 | 对本 Issue 的处理 |
| --- | --- | --- |
| Flutter 工程 | 已初始化 | 仅生成 Android 平台，保留全部文档和 Git 配置 |
| Flutter 和依赖精确版本 | 已锁定 | Flutter 3.44.7 stable（`.flutter-version`）；`lottie` 3.5.1、`audioplayers` 6.8.1；锁文件已提交 |
| 正式素材 | 未交付 | 使用同名占位素材完成代码；正式内容验收保持未勾选 |
| 正式 `applicationId` | 未确认 | 暂用 `com.example.child_doctor_app`；正式发包前只改一次 |
| 正式签名 | 未提供 | Debug/内部 release 构建继续（release 使用 debug 证书）；keystore 和密码不得进 Git |
| 最低性能目标机和平板 | 未指定 | 自动化和模拟尺寸已完成；真机性能结论标记 `[待验证]` |
| 目标年龄和洗手文案内容确认 | 未完成 | 不改固定文案；正式对外使用前由内容负责人确认 |

仅当 Flutter/Android SDK 不存在、工程无法初始化且需要安装新工具，或依赖解析在安全重试后仍受外部网络阻断时，才把开发标为 blocked。报告已执行命令、完整错误和需要的外部操作，不要用猜测代替证据。

## 产品范围

### 本 Issue 必须实现

- Android 8.0（API 26）及以上的 Flutter APK。
- 横屏检查室、竖屏门禁和沉浸式显示。
- `ready`、`scanning`、`result` 三个业务状态。
- 本地 Lottie 扫描、扫描底音、虫子音效和洗手配音。
- 「开始扫描」「再看一次」、资源准备和资源失败界面。
- 重复点击保护、旧回调隔离、动画 watchdog。
- 转竖屏、切后台、系统返回和音频焦点变化处理。
- 手机和平板的 16:9 舞台适配。
- 单元、Widget、Golden 和集成测试。
- Debug APK、内部 release APK、构建信息和 SHA-256。
- 自动化检查完成后的真机验收记录。

### 不在范围内

- iOS、Web、Windows、macOS 或 Linux 客户端。
- 应用商店上架、在线更新或远程素材替换。
- 标题页、菜单、设置、账号、登录、埋点、广告或付费。
- 网络、后台服务、数据库、偏好设置和业务数据持久化。
- 相机、麦克风、相册、定位、蓝牙、通知或存储权限。
- 扫描真实小孩、采集人体数据、医学诊断、病名、器官标注或检查报告。
- 「洗过手 / 没洗手」对比、小肠大肠知识、多语言和可跳过扫描。
- 为未来需求预建路由框架、通用状态管理、依赖注入容器或数据层。

## 固定产品行为

### 文案

| 标识 | 必须逐字使用的原文 |
| --- | --- |
| `rotateHint` | 请把设备横过来 |
| `preparing` | 正在准备… |
| `startScan` | 开始扫描 |
| `washHint` | 不洗手就吃东西，肚子里会长虫子。快去洗手！ |
| `replay` | 再看一次 |
| `loadFailed` | 加载失败，请重新打开应用 |

按钮、提示和错误文案由 Flutter 绘制，不得烧进背景图或 Lottie。`washHint` 的界面文字、配音脚本、常量和测试必须一致。

### 状态

```dart
enum ExamPhase { ready, scanning, result }

enum ResourceStatus { loading, ready, failed }
```

方向、资源和生命周期是环境状态，不得加入 `ExamPhase`。

`ResourceStatus` 只表示必需的 Lottie 是否可用。音频 `prepare` 或播放失败不把资源改成 `failed`，也不阻止扫描和文字结果。

| 事件 | 前置条件 | 必须执行的动作 | 结果 |
| --- | --- | --- | --- |
| `resourcesReady` | Lottie composition 加载成功 | 保存动画实际时长，资源变为 `ready` | 「开始扫描」可用 |
| `resourcesFailed` | Lottie composition 加载失败 | 资源变为 `failed` | 只显示固定错误文案 |
| `startScan` | `ready`、横屏、`resumed`、资源就绪 | 先进入 `scanning` 并递增 `runId`，再启动扫描底音；`ExamScreen` 观察状态后启动动画 | 重复调用被忽略 |
| `replay` | `result`、横屏、`resumed`、资源就绪 | 停配音、进入 `scanning`、递增 `runId`；`ExamScreen` 观察状态后归零动画 | 新一轮从第 0 帧开始 |
| `wormCue` | `scanning`、`runId` 匹配、本轮未播放 | 播放一次虫子音效并记录已触发 | 同一轮不重复 |
| `completeScan` | `scanning`、`runId` 匹配 | 停扫描底音、取消 watchdog、进入 `result`、播放一次配音 | Lottie 保持末帧 |
| `watchdogTimeout` | 超过动画实际时长 1,000 ms，仍为同轮 `scanning` | 停底音，记录调试原因并进入 `result`；`ExamScreen` 停动画并定位末帧 | 兜底完成；测试中出现算缺陷 |
| `abort` | 任意业务状态 | 使当前 `runId` 失效，取消 watchdog，停止三个播放器，切回 `ready` | 可重复调用，不抛未处理异常 |
| `systemBack` | 任意业务状态 | 等待 `abort`，再 `SystemNavigator.pop()` | 关闭 Activity，不宣称杀死进程 |

所有动画、timer 和音频延迟回调都携带创建时的 `runId`。回调到达时，只要 `runId` 已变化或当前状态不匹配，就丢弃，不产生音频和状态变化。

### 方向和生命周期

- 不在 AndroidManifest 设置 `android:screenOrientation="landscape"`。
- 不调用只允许 landscape 的 `SystemChrome.setPreferredOrientations`。
- `MediaQuery.size.height > MediaQuery.size.width` 时只显示竖屏门禁。
- `OrientationGate` 用 `WidgetsBindingObserver.didChangeMetrics` 识别横竖变化，只在方向真正改变时发一次事件；不能在 `build` 中调用 `abort`。
- 进入竖屏时，如果当前是 `scanning` 或 `result`，执行 `abort`。再次横屏显示 `ready`。
- `paused` 或 `hidden` 执行 `abort`；`inactive` 不迁移状态，但不接受新的 `startScan` 和 `replay`。
- `resumed` 重新应用 `SystemUiMode.immersiveSticky`。
- 根节点使用 `PopScope(canPop: false)`；返回回调等待 `abort` 后再关闭 Activity。
- 音频焦点被其他 App 抢占时允许系统暂停或降低声音，画面继续；重新获得焦点后不补播已经触发的虫子音效或洗手配音。

### 画面和交互

- 根节点使用 `SafeArea`，挖孔、圆角和系统手势区内不放文字或按钮。
- 横屏业务内容是居中的 16:9 舞台，背景和 Lottie 使用 `BoxFit.contain`，不能裁切或拉伸。
- 20:9 手机左右留边；16:10 和 4:3 平板上下留边。留边颜色与检查室背景协调。
- 主按钮点击区域不小于 160 × 64 dp，文字不小于 22 sp。
- 系统字体缩放 1.3 倍时，固定文案和按钮不截断、不溢出。
- `ready + loading` 显示「正在准备…」，不显示可点击按钮。
- `ready + ready` 显示唯一主按钮「开始扫描」。
- `ready + failed` 显示「加载失败，请重新打开应用」，不显示不可用按钮。
- `scanning` 不显示按钮；点击、双击和长按都没有业务效果。
- `result` 保留 Lottie 末帧，叠加宽度不超过舞台 75% 的浅色半透明提示板。提示板显示不超过两行的 `washHint` 和「再看一次」。
- 竖屏门禁有一个横向设备图标，整页 Semantics 文案为「请把设备横过来」。
- 占位设计色固定为：舞台外 `#16324F`、主按钮 `#FFB703`、按钮文字 `#3A2A00`、结果板 `#FFF8E7` 且 94% 不透明、正文 `#203040`。正式视觉稿到位后统一替换 design tokens 和 Golden，不能散落硬编码。

### 扫描时序

- Lottie 以 composition 完成回调作为正常结束条件。
- 开发基线时长是 12,000 ms；占位和正式素材都应在 11,500～12,500 ms。
- 正式/占位 Lottie 基线：1920 × 1080、30 fps、约 360 帧、全矢量、无外部位图和文字。
- 扫描底音从第 0 帧开始，在完成、`abort` 或 watchdog 时停止。
- 动画进度第一次达到 58% 时播放一次虫子音效。
- watchdog 是 `composition.duration + 1,000 ms`，不能写死 13 秒，也不能代替完成回调。
- `result` 配音只播放一次，不循环；点击「再看一次」先停止配音。

占位和正式 Lottie 都按下列分镜制作，允许在总时长范围内微调，但虫子音效进度和测试必须同步：

| 时间 | 画面 | 声音 |
| --- | --- | --- |
| 0.0～1.0 s | 机器亮起，扫描线出现 | 扫描底音开始 |
| 1.0～4.5 s | 扫描线扫过卡通小孩 | 扫描底音持续 |
| 4.5～7.0 s | 肚子逐渐半透明，露出简化肠道 | 扫描底音持续 |
| 约 7.0 s | 圆滚滚的虫子出现 | 虫子音效一次 |
| 7.0～11.5 s | 虫子蠕动，画面停留到足以看清 | 扫描底音持续 |
| 11.5～12.0 s | 扫描线熄灭，停在适合叠加结果的末帧 | 扫描底音停止 |

### 素材契约

| 文件 | 必须满足的规格 | 验收重点 |
| --- | --- | --- |
| `assets/images/exam_room.webp` | 1920 × 1080、sRGB，不含按钮和文字 | `BoxFit.contain` 下关键内容不被裁 |
| `assets/lottie/scan.json` | 1920 × 1080、30 fps、约 360 帧、11.5～12.5 秒、全矢量、无文字和外部位图 | Flutter 真机无缺图、遮罩错位或不支持效果 |
| `assets/audio/scan_loop.mp3` | 单声道、44.1 kHz、建议 96～128 kbps、可无缝循环 | 循环点无爆音；中断后 200 ms 内停止 |
| `assets/audio/worm_cue.mp3` | 单声道、44.1 kHz、建议 96～128 kbps、单次短音效 | 不刺耳，不覆盖洗手配音 |
| `assets/audio/wash_hint.mp3` | 单声道、44.1 kHz、建议 96～128 kbps | 正式版逐字等于 `washHint`，前后无长静音 |
| `assets/icon/app_icon_1024.png` | 1024 × 1024、sRGB | 生成小图标后仍可识别，不含细小文字 |

## 技术实现约束

### 工程初始化

- 在仓库根目录初始化，仅生成 Android 平台；保留现有 `AGENTS.md`、`CONTEXT.md`、`docs/` 和 `.gitignore` 内容。
- 项目名使用 `child_doctor_app`。正式 ID 未确认前使用 `com.example.child_doctor_app`。
- `minSdk` 设为 26；`targetSdk` 和 `compileSdk` 使用锁定 Flutter stable 模板实际生成并验证的值。
- App 显示名称为「肚子扫描仪」。
- Android application 设置 `android:allowBackup="false"` 和 `android:usesCleartextTraffic="false"`。
- Manifest 不声明 `android.permission.INTERNET`，也不声明本 Issue 范围外的权限。
- 新增 `.flutter-version`，只写实际使用的精确 Flutter 版本；提交该文件、`pubspec.lock`、Gradle wrapper 和 Android 工程配置。首版不为此额外引入版本管理器。
- 初始化完成后更新根 `AGENTS.md` 的「当前可用命令」，删除“尚未初始化 Flutter 工程”的过时事实。

可使用下列命令作为初始化意图，具体参数以本机 Flutter 帮助和执行结果为准：

```bash
flutter create --platforms=android --org com.example --project-name child_doctor_app .
```

如果命令会覆盖已有文件，先保存差异并在生成后合并，不能丢失仓库文档和规则。

### 依赖

运行时依赖只允许：

- Flutter SDK
- `lottie`：播放包内 `assets/lottie/scan.json`
- `audioplayers`：使用本地 `AssetSource` 播放三段 MP3

开发和测试依赖：

- `flutter_lints`
- `flutter_test`
- `integration_test`

如需新增依赖，先证明 Flutter SDK 或上述依赖无法完成，并在 PR/交付说明中写明用途、代价和删除条件。禁止引入路由、网络、数据库、日志上传、通用状态管理、依赖注入或响应式布局包。

### 模块和 interface

按以下模块职责实现。可以合并过小文件，但不能改变 interface 和所有权：

| 模块 | Interface | 实现责任 |
| --- | --- | --- |
| `AppShell` | Flutter 根 Widget | 主题、沉浸式显示、单路由、生命周期和根级返回处理 |
| `OrientationGate` | 接收业务 `child` 和方向变化回调 | 竖屏门禁、方向去重、进入竖屏时触发中断 |
| `ExamCoordinator` | 只读状态；`resourcesReady`、`resourcesFailed`、`startScan`、`replay`、`completeScan`、`playWormCue`、`abort` | 唯一状态写入口；前置条件、`runId`、watchdog 和音频编排 |
| `ExamScreen` | 读取协调器状态并上报动画事件 | 渲染三态；在 `scanning`/`result` 间保留同一 Lottie Widget 和 `AnimationController`；状态进入 `result` 时确保控制器停在末帧 |
| `ExamAudio` | `prepare`、`startScanBed`、`stopScanBed`、`playWormCue`、`playWashHint`、`stopAll` | 隐藏播放器数量、循环、资源和停止行为 |
| `LocalAudio` | `ExamAudio` adapter | 使用三个独立 `AudioPlayer`，分别管理底音、虫子音效和配音 |
| `FakeExamAudio` | 测试 adapter | 记录调用、模拟错误，不加载平台播放器 |

`ExamCoordinator` 是具体模块，不需要再抽象一个只有一个实现的 coordinator interface。`ExamAudio` 有生产和测试两个 adapter，这个 seam 必须保留。计时器/时钟要可控，单元测试不能真实等待 12 秒。

Widget 不直接访问 `AudioPlayer`，不在 `build` 中启动 timer、动画、音频、状态迁移或资源加载。动画启停放在 Widget 生命周期或状态监听回调中：进入 `scanning` 时从第 0 帧播放，进入 `result` 时停在末帧，进入 `ready` 时移除并释放。`AnimationController`、播放器、observer 和 timer 都有单一所有者，并在中断和 `dispose` 时释放。

### 目标目录

```text
lib/
  main.dart
  app.dart
  exam/
    exam_phase.dart
    exam_coordinator.dart
    exam_screen.dart
    orientation_gate.dart
    widgets/
      ready_view.dart
      scanning_view.dart
      result_view.dart
      rotate_hint_view.dart
  audio/
    exam_audio.dart
    local_audio.dart
  resources/
    asset_paths.dart
    copy.dart
assets/
  audio/
    scan_loop.mp3
    worm_cue.mp3
    wash_hint.mp3
  images/
    exam_room.webp
  lottie/
    scan.json
  icon/
    app_icon_1024.png
test/
  exam/
  audio/
  golden/
integration_test/
  exam_flow_test.dart
```

### 素材处理

- `pubspec.yaml` 逐个声明三个运行时音频、背景图和 Lottie，不用目录通配声明。
- `assets/icon/app_icon_1024.png` 只用于生成并提交 Android `mipmap-*`，不作为运行时 asset。
- 如果正式素材未到，所有占位文件仍须是有效格式并能在 Android 真机加载。
- 占位背景图和 Lottie 要明确表现为卡通占位内容，不使用真实人体或医疗影像。
- 占位音频不得下载来源不明的素材。不能提供逐字洗手配音时，保留有效占位音频并在交付证据中标为 `[待替换]`，不得勾选正式内容验收。
- 增加素材来源/许可记录，区分 Agent 生成的占位素材与正式素材。
- Lottie 加载失败会阻止开始扫描；任一音频失败只让本轮静默继续，不阻止状态迁移，也不弹技术错误。

## 实施清单

Agent 按顺序执行并在交付说明中逐项报告。代码未完成前不要开始真机验收。

### 1. 工具链和工程

- [x] 记录 `flutter --version`、`dart --version` 和 Android SDK 状态。
- [x] 初始化只含 Android 的 Flutter 工程，保留现有文档和 Git 配置。
- [x] 锁定 Flutter/依赖版本并提交锁文件。
- [x] 配置 App 名称、API 26、临时 applicationId 和 Android 安全属性。
- [x] 更新根 `AGENTS.md` 的真实命令和当前仓库状态。

### 2. 资源和文案

- [x] 建立固定文案和资源路径常量，业务 Widget 不复制字符串。
- [x] 放入正式素材，或放入格式、路径和时长合规的占位素材。
- [x] 逐个声明运行时 assets，生成 Android launcher icon。
- [x] 记录所有素材来源、许可和正式/占位状态。
- [x] 实现 Lottie 异步预加载；首帧先显示检查室和「正在准备…」。

### 3. 状态和音频

- [x] 实现 `ExamPhase`、`ResourceStatus` 和只读协调器状态。
- [x] 实现全部合法状态迁移、非法事件忽略和先改状态再执行副作用。
- [x] 实现递增 `runId`，隔离旧动画、音频和 watchdog 回调。
- [x] 注入可控 timer/clock，watchdog 使用动画实际时长加 1,000 ms。
- [x] 实现 `ExamAudio`、三个播放器的 `LocalAudio` 和 `FakeExamAudio`。
- [x] 确保 `abort`、`stopAll` 和 `dispose` 可重复调用，不泄漏异常或播放器。

### 4. 界面和动画

- [x] 实现 `OrientationGate`、竖屏图标和整页 Semantics。
- [x] 实现 16:9 舞台、SafeArea、留边和占位颜色 design tokens。
- [x] 实现 `ready` 的 loading、ready、failed 三种资源画面。
- [x] 实现 `scanning`，播放期间没有按钮，普通手势不改变状态。
- [x] 监听 Lottie 完成和 58% 进度，回调携带当前 `runId`。
- [x] 实现 `result` 末帧保留、半透明提示板、固定文案和「再看一次」。
- [x] 满足四种基线尺寸和系统字体 1.3 倍要求。

### 5. 中断和平台行为

- [x] 实现 `resumed`、`inactive`、`paused`、`hidden` 行为。
- [x] 实现转竖屏中断，转回横屏不续播。
- [x] 实现根 `PopScope`，停止副作用后关闭 Activity。
- [x] 进入前台时重设沉浸式显示。
- [x] 配置音频焦点；中断不重播已经触发过的配音。
- [ ] 验证后台和退出后没有音频残留。

### 6. 测试、构建和文档

- [x] 完成下文列出的单元、Widget、Golden 和集成测试。
- [x] 运行格式化、静态检查和全部自动化测试。
- [x] 构建 Debug APK 和内部 release APK；正式签名未提供时只能使用内部测试签名，不能称为正式发布包。
- [x] 检查合并 Manifest 和 APK 权限，不只检查源码 Manifest。
- [x] 记录 APK 路径、体积和 SHA-256，不把 APK 提交到 Git。
- [ ] 两轮读取完整 `git diff`，修复正确性、安全、维护性和性能问题。
- [x] 更新设计文档中已经确定的工具链版本、依赖、文件名或待确认项。
- [x] 代码门槛全部通过后，把状态交接为 `Ready for Device QA`。

## 自动化验收

### 必须通过的命令

工程初始化后，以根 `AGENTS.md` 中记录的实际命令为准，至少包含：

```bash
flutter pub get
dart format --set-exit-if-changed lib test integration_test
flutter analyze
flutter test
flutter build apk --debug
flutter build apk --release
```

如果某条命令因没有真机而不能运行，只允许推迟 Android 真机集成测试。单元、Widget、Golden、静态检查和 APK 构建不能因此跳过。命令失败时修复根因，不删除测试、不放宽断言。

### 单元测试

| ID | 场景 | 断言 |
| --- | --- | --- |
| U01 | 初始状态 | `phase=ready`、`resourceStatus=loading`、无活动 watchdog |
| U02 | 资源加载成功 | 保存 composition duration，资源变为 `ready`，可开始扫描 |
| U03 | 资源加载失败 | 资源变为 `failed`，`startScan` 不产生状态或音频变化 |
| U04 | 合法开始 | `ready → scanning`，`runId + 1`，扫描底音只调用一次 |
| U05 | 连续开始 5 次 | 只有第一次有效，只有一个 run 和一份底音 |
| U06 | 虫子进度重复回调 | 同一 `runId` 只播放一次虫子音效 |
| U07 | 正常完成 | 停底音、取消 watchdog、`scanning → result`、配音一次 |
| U08 | watchdog | 到 `duration + 999 ms` 不触发；再过 1 ms 进入 `result` |
| U09 | 正常完成后 watchdog 晚到 | 状态和音频不再变化 |
| U10 | replay | 停配音、`result → scanning`、新 `runId`、虫子标记重置 |
| U11 | 上一轮完成回调晚到 | 旧 `runId` 被丢弃，不提前结束新一轮 |
| U12 | abort | 任意状态回到 `ready`，timer 取消，`stopAll` 一次 |
| U13 | 重复 abort/dispose | 不抛异常，不重复产生业务事件 |
| U14 | inactive | 不迁移当前状态，拒绝新 `startScan`/`replay` |
| U15 | paused/hidden | 执行 abort，恢复后是 `ready` |
| U16 | 音频 adapter 抛错 | 状态机继续，无未处理异常，文字结果仍可达 |

### Widget 和 Golden 测试

| ID | 场景 | 断言 |
| --- | --- | --- |
| W01 | 竖屏启动 | 只有转横提示，没有检查室按钮，Semantics 文案正确 |
| W02 | 横屏 loading | 检查室和「正在准备…」可见，没有可点主按钮 |
| W03 | 横屏 ready | 只有「开始扫描」主按钮 |
| W04 | 资源失败 | 固定失败文案可见，没有失效按钮 |
| W05 | scanning | Lottie 可见，所有业务按钮不可见，点击不改变状态 |
| W06 | result | 末帧仍在，提示板、完整洗手文案和「再看一次」可见 |
| W07 | 字体 1.3 倍 | 固定文案和按钮无 overflow、截断或安全区越界 |
| W08 | 640 × 360 | 16:9 舞台铺满可用区，按钮和文案不碰安全区 |
| W09 | 800 × 360 | 左右留边，场景不拉伸 |
| W10 | 960 × 600 / 1024 × 768 | 上下留边，舞台居中，结果布局稳定 |

Golden 至少覆盖 `ready`、`scanning` 代表帧和 `result`，尺寸覆盖 16:9 手机、20:9 手机和 4:3 平板。不得不审图就更新基线，也不得靠隐藏 overflow 让测试通过。

### 集成测试

| ID | 场景 | 断言 |
| --- | --- | --- |
| I01 | 横屏完整流程 | 开始后进入扫描，完成后进入结果，配音触发一次 |
| I02 | 重复点击 | 连点开始只启动一轮 |
| I03 | 再看一次 | 从结果直接从第 0 帧开始新扫描 |
| I04 | 扫描中转竖屏 | 立即中断，转回横屏显示检查室 |
| I05 | 扫描中切后台 | 后台无音频，回来显示检查室 |
| I06 | 三态系统返回 | Activity 关闭，退出后无残留音频 |
| I07 | 飞行模式 | 冷启动和完整流程与联网状态相同 |
| I08 | 连续重播 20 轮 | 无崩溃、无音频叠加、没有明显持续内存增长 |

集成测试允许用测试构建缩短动画，但测试开关不能进入正式运行路径。至少一次最终真机流程必须使用 11.5～12.5 秒的正式时长。

### 权限和构建检查

- [x] `android/app/src/main/AndroidManifest.xml` 没有 `INTERNET` 和范围外权限。
- [x] release 合并 Manifest 没有依赖带入的额外权限。
- [x] APK 权限检查只包含预期项；把 `apkanalyzer`、`aapt` 或安装后 `dumpsys package` 的实际输出附到交付证据。
- [x] `android:allowBackup="false"`、`android:usesCleartextTraffic="false"` 生效。
- [x] Manifest 没有锁死 landscape。
- [ ] APK 在飞行模式下不访问网络、不报网络错误。
- [x] 仓库中没有 keystore、签名密码、真实 `key.properties` 或构建出的 APK。

## 真机验收：代码完成后执行

真机验收是最后阶段。开始前必须满足：

- 自动化命令全部通过。
- 候选 APK 已生成并记录 commit、Flutter 版本、applicationId、versionName、versionCode、体积和 SHA-256。
- 使用正式素材时，来源和许可已确认；使用占位素材时，内容类用例明确标为 blocked，不能伪装通过。
- 测试人员拿到最低 Android 版本手机、常用手机和一台平板。没有指定型号时先记录现有设备结果，性能结论保持 `[待验证]`。

### 设备记录

| 角色 | 品牌/型号 | Android | 分辨率/比例 | CPU/内存 | APK SHA-256 | 结果 |
| --- | --- | --- | --- | --- | --- | --- |
| 最低版本手机 | 待填 | 8.0 / API 26 | 待填 | 待填 | 待填 | 待测 |
| 常用手机 | 待填 | 待填 | 待填 | 待填 | 待填 | 待测 |
| 平板 | 待填 | 待填 | 待填 | 待填 | 待填 | 待测 |

### 真机用例

| ID | 操作 | 预期结果 | 证据 | 结果 |
| --- | --- | --- | --- | --- |
| A01 | 竖屏冷启动 | 第一屏只有转横提示，检查室按钮不露出 | 照片/录屏 | 待测 |
| A02 | 转成两个方向的横屏 | 自动显示检查室；背景不拉伸；按钮不碰挖孔、圆角和手势区 | 两个方向截图 | 待测 |
| A03 | 连点「开始扫描」5 次 | 只开始一轮，只播放一份扫描底音 | 录屏和日志 | 待测 |
| A04 | 扫描期间点击、双击和长按 | 不跳过、不暂停、不出现按钮 | 录屏 | 待测 |
| A05 | 使用正式时长正常看完 | 11.5～12.5 秒进入结果；配音一次；文字逐字一致 | 录屏和计时 | 待测 |
| A06 | 配音中点击「再看一次」 | 配音在 200 ms 内停止；动画从第 0 帧开始；本轮虫子音效一次 | 录屏 | 待测 |
| A07 | 扫描中转竖屏再转回 | 动画停止，音频在 200 ms 内停止；横屏后是检查室，不续播 | 录屏 | 待测 |
| A08 | 扫描中按 Home，等待 3 秒后返回 | 后台无声音；返回后是检查室 | 录屏 | 待测 |
| A09 | `ready`、`scanning`、`result` 分别系统返回 | Activity 关闭，音频在 200 ms 内停止，后台没有残留 | 三段录屏 | 待测 |
| A10 | 飞行模式冷启动并完成一次检查 | 行为与联网状态相同，没有网络错误 | 录屏 | 待测 |
| A11 | 系统音量设为零 | 流程不受阻，洗手文字完整可见 | 截图 | 待测 |
| A12 | 连续「再看一次」20 轮 | 无崩溃、无叠音、无明显持续内存增长 | 录屏和 profiler 截图 | 待测 |
| A13 | 冷启动连续测 3 次 | 最慢一次：首帧 ≤ 2 秒，按钮可用 ≤ 3 秒 | 计时记录 | 待测 |
| A14 | 扫描动画 profile | 没有连续 3 帧以上的肉眼停顿；30 fps 单帧目标 ≤ 33 ms | Flutter profile 截图 | 待测 |
| A15 | 虫子出现与音效 | 音效起点与画面偏差 ≤ 200 ms | 慢放录屏/音轨 | 待测 |
| A16 | 覆盖安装上一候选版本 | 安装成功、签名一致、versionCode 已递增 | 安装记录 | 待测 |

每次修复真机问题后，重新构建 APK，更新 SHA-256，并重跑受影响用例及 A09、A12。不同 SHA-256 的证据不能混在同一轮结果里。

## 追踪矩阵

Agent 完成代码后把表中的预期路径和测试 ID 更新为真实文件及测试名，不能填写尚不存在的路径。

| 需求 | 实现位置（完成后更新） | 自动化证据（完成后更新） | 真机证据 |
| --- | --- | --- | --- |
| P0-01 竖屏门禁 | `lib/exam/orientation_gate.dart`、`lib/exam/widgets/rotate_hint_view.dart` | W01、W08；`test/exam/orientation_gate_test.dart`；`test/exam/app_shell_test.dart`「扫描中转竖屏」（I04 自动化替代） | A01、A02、A07 |
| P0-02 检查室 | `lib/exam/widgets/ready_view.dart` | W02、W03、W04；Golden ready×3 | A02 |
| P0-03 自动扫描 | `lib/exam/exam_coordinator.dart`、`lib/exam/exam_screen.dart`、`lib/exam/widgets/scanning_view.dart` | U04～U11、W05、W06、I01～I03 | A03～A05 |
| P0-04 扫描音频 | `lib/audio/exam_audio.dart`、`lib/audio/local_audio.dart` | U06、U16；`test/audio/local_audio_test.dart`；I01 | A03、A06、A15 |
| P0-05 洗手提示 | `lib/exam/widgets/result_view.dart`、`lib/resources/copy.dart` | U07、W06、I01 | A05 |
| P0-06 再看一次 | `lib/exam/exam_coordinator.dart`、`lib/exam/widgets/result_view.dart` | U10、U11、I03、I08 | A06、A12 |
| P0-07 中断处理 | `lib/app.dart`、`lib/exam/orientation_gate.dart`、`lib/exam/exam_coordinator.dart` | U12～U15；`test/exam/app_shell_test.dart`（I04/I06 自动化替代） | A07～A09 |
| P0-08 离线运行 | `android/app/src/main/AndroidManifest.xml`（无 INTERNET 权限） | release 合并 Manifest 与 APK 权限检查 | A10 |

## 交付证据模板

Agent 完成开发后，在 Issue 评论或 PR 描述中按以下格式交付：

```markdown
## 实现结果

- 状态：Ready for Device QA / Blocked
- Commit：<sha>
- Flutter：<flutter --version 完整摘要>
- Dart：<version>
- applicationId：<value>
- versionName/versionCode：<value>
- 素材：正式 / 占位；待替换项：<list>

## 自动化检查

| 命令 | 结果 | 摘要 |
| --- | --- | --- |
| flutter pub get | PASS/FAIL | |
| dart format --set-exit-if-changed lib test integration_test | PASS/FAIL | |
| flutter analyze | PASS/FAIL | |
| flutter test | PASS/FAIL | tests: <count> |
| flutter build apk --debug | PASS/FAIL | path/size |
| flutter build apk --release | PASS/FAIL | path/size |
| APK/Manifest 权限检查 | PASS/FAIL | requested permissions |

## APK

- 路径：<path>
- 大小：<bytes/MiB>
- SHA-256：<hash>
- 签名：debug/internal/formal；不包含密码

## 未完成或待真机验证

- <item + reason + impact>

## 自审

- 第一轮：产品正确性、安全、错误路径和中断行为
- 第二轮：模块 interface、资源所有权、性能、测试和文档同步
```

真机阶段使用上文设备表和用例表，不用一句“真机通过”代替逐项证据。

## 完成定义

### Agent 实现完成：可转 `Ready for Device QA`

- [ ] Flutter Android 工程、运行代码、占位/正式素材和测试全部提交。
- [x] P0-01～P0-08 都有实现和自动化证据。
- [x] 格式化、静态检查、单元、Widget、Golden 和可执行的集成测试全部通过。
- [x] Debug 和内部 release APK 构建成功，SHA-256 和构建信息齐全。
- [x] 合并 Manifest 和 APK 权限检查通过；没有网络、采集、持久化或遥测能力。
- [x] 没有任务范围内的 TODO/FIXME、跳过测试、泄漏资源或未处理异步错误。
- [x] 根 `AGENTS.md` 和产品及技术设计文档已同步到实际工程事实。
- [x] 已明确列出占位素材、正式 ID、签名、内容确认和真机验证的剩余项。

### Issue 完成：可以关闭

- [ ] 正式图片、Lottie、图标和三段音频已替换，占位素材已移除。
- [ ] 正式素材来源、许可、目标年龄和洗手文案已经负责人确认。
- [ ] 正式 `applicationId`、签名、versionName 和 versionCode 已确定。
- [ ] 三类真机完成 A01～A16，失败项已修复并用同一候选 APK 复测。
- [ ] 最低目标设备满足启动、动画和音画同步性能门槛。
- [ ] 覆盖安装成功，正式 APK、SHA-256、构建信息和验收记录已归档。

## 禁止的完成方式

- 不得因为占位素材能播放就宣称正式内容完成。
- 不得因为模拟器通过就勾选真机用例或低端机性能。
- 不得用 `Future.delayed(12s)` 代替 Lottie 完成回调。
- 不得锁死 Activity 为 landscape 来隐藏竖屏适配问题。
- 不得在 Widget `build` 中启动播放、计时或状态迁移。
- 不得复用一个播放器承担三类声音。
- 不得把音频失败变成扫描失败，也不得忽略 Lottie 加载失败。
- 不得加入 `INTERNET`、相机等权限后只在说明里声称“没有使用”。
- 不得提交 keystore、密码、APK、构建缓存或来源不明素材。
- 不得删测试、改松断言、盲目更新 Golden 或跳过失败命令来获得绿色结果。

---

## 交付证据（Agent 实现阶段）

> 生成时间：2026-08-24。状态：`Ready for Device QA`。

### 实现结果

- 状态：Ready for Device QA
- Commit：`afdff4a`（实现）+ `e7bb172`（文档同步）
- Flutter：3.44.7 stable（Dart 3.12.2，revision 84fc5cbb22，2026-07-17）；`.flutter-version` 已提交
- Dart：3.12.2
- applicationId：`com.example.child_doctor_app`（临时，正式发包前只改一次）
- versionName/versionCode：1.0.0 / 1
- 素材：全部占位（Agent 程序化生成，来源记录见 `docs/素材来源与许可.md`）；待替换：`wash_hint.mp3`（非逐字配音）、全部正式插画/动画/音频/图标

### 自动化检查

| 命令 | 结果 | 摘要 |
| --- | --- | --- |
| flutter pub get | PASS | 依赖锁定于 `pubspec.lock` |
| dart format --set-exit-if-changed lib test integration_test | PASS | 25 个文件格式一致 |
| flutter analyze | PASS | No issues found |
| flutter test | PASS | 58 个测试：U01~U16 协调器单元测试 19、LocalAudio 6、Widget/门禁/AppShell 24、Golden 9、scan.json 契约 4（含解析、时长、无位图、无文字层） |
| flutter build apk --debug | PASS | build/app/outputs/flutter-apk/app-debug.apk（153,124,881 字节 / 146.0 MiB） |
| flutter build apk --release | PASS | build/app/outputs/flutter-apk/app-release.apk（43.7 MB） |
| APK/Manifest 权限检查 | PASS | release 合并 Manifest 无 INTERNET；APK 权限仅 `com.example.child_doctor_app.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`（自声明签名级权限，androidx 自动生成）；`allowBackup=false`、`usesCleartextTraffic=false` 生效；无 screenOrientation 锁定 |

### APK

- 路径：build/app/outputs/flutter-apk/app-release.apk
- 大小：45,855,640 字节（43.7 MiB）
- SHA-256：`f1c6c945d3e28aeba123758727b58a52081cd3b5c65472aebaa2055b5e348966`
- 签名：内部测试签名（Android Debug 证书，SHA-256 3d1906ae7cbc2f3578772acfe211ac40d999da92f5fecfb21d69939dae58d6a3）；正式签名和密码未提供，不得称为正式发布包
- Debug APK SHA-256：`f1ac26242b621e3627c53101093ef117e3ebd6065d84f36c3472eac088f9bd16`（Debug 变体含 Flutter 调试工具链自带的 INTERNET 权限，正式包不含）

### 未完成或待真机验证

- 真机集成测试（I01、I02、I03、I05、I08）：已编写并随仓库交付，但本机唯一真机（24090RA29C，Android 16）拒绝 adb 安装（`INSTALL_FAILED_USER_RESTRICTED: Install canceled by user`，小米设备需在开发者选项开启「USB 安装」）。开启后执行 `flutter test integration_test -d <device-id>` 复跑。
- I04（转竖屏）：真机无法注入 metrics 变化，自动化证据由 `test/exam/app_shell_test.dart`「扫描中转竖屏」承担；真机用例 A07 待测。
- I06（返回关闭 Activity）：`SystemNavigator.pop()` 会终止测试进程，自动化证据由 `test/exam/app_shell_test.dart`「三态系统返回」承担；真机用例 A09 待测。
- I07（飞行模式）：需 adb 控制飞行模式，无法在测试内切换；离线能力由「release 无 INTERNET 权限」保证；真机用例 A10 待测。
- 真机用例 A01～A16：未执行，全部待测；最低 API 26 手机、常用手机、平板三档设备未指定。
- 性能结论（启动 ≤2 s/≤3 s、30 fps 无连续掉帧、音画偏差 ≤200 ms）：[待验证]。
- 正式素材、正式 applicationId、正式签名、目标年龄与洗手文案负责人确认：未完成，见「当前仓库状态」表。

- 依赖说明（Issue「依赖」条款要求新增依赖写明用途、代价和删除条件）：`fake_async` 1.3.3 只用于协调器单元测试的可控时钟；`audioplayers_platform_interface` 7.2.0 只用于 `LocalAudio` 单元测试的假平台（避免 MethodChannel 真调用），两者都是 dev_dependencies，不进 APK，删除条件已写入设计文档 §8.2。
- 设计文档 §8 的 `LifecycleAndBack` 模块并入 `AppShell`（Issue 模块表中 `AppShell` 本就承担生命周期和根级返回处理），生命周期前置条件由 `ExamCoordinator.onAppLifecycle` 接收——这是 U14/U15（inactive 拒绝新事件、paused/hidden 中断）能作为协调器单元测试的前提。

### 与 Issue 接口表的偏离（有依据）

- `ExamAudio` 增加 `dispose()`：Issue 模块表列了 6 个方法，但「播放器有单一所有者并在 dispose 时释放」要求 AppShell 释放音频；没有 dispose 只能让 AppShell 向下转型到 `LocalAudio`（具体类型耦合）。接口补齐生命周期方法后，生产/测试实现都从同一接口释放，符合「测试使用 fake 时跨同一个 interface」。代价：接口多一个方法，`FakeExamAudio`/`CountingAudio` 同步实现。
- watchdog 兜底完成时也播放一次洗手配音：Issue 事件表 `watchdogTimeout` 只写「进入 result」，但根 `AGENTS.md` 产品边界要求「动画结束后必须显示并播放洗手提示」，设计文档流程图也把超时路由到带配音的洗手提示页。两者冲突时按 AGENTS.md 的产品规则执行。

### 自审

- 第一轮（产品正确性、安全、错误路径和中断行为）：已执行，读取完整 `git diff` 后修复问题：真机 Lottie 解析错误（scan.json 位置关键帧被序列化为字符串）、watchdog 与动画完成回调在测试中的竞争、重复 dispose 断言、扫描中点击不改变状态等。
- 第二轮（模块 interface、资源所有权、性能、测试和文档同步）：已执行；`/code-review`（mattpocock code-review 技能）对实现做了 Standards/Spec 双轴审查，问题已修复。
