# AGENTS.md

肚子扫描仪是给小孩观看的横屏卡通 Android App。成人打开设备，小孩点击“开始扫描”，约 12 秒后看到卡通小孩肚子里的虫子和固定洗手提示。首版是可侧载的 Flutter Android APK，只使用包内图片、Lottie 和音频；没有账号、后台、网络、用户数据或医学诊断。Flutter Android 工程已初始化（精确版本见 `.flutter-version`），依赖锁定在 `pubspec.lock`。

用户沟通、文档正文和代码注释默认使用中文；Flutter、Android、Dart API 名称和资源字段保持原名。Commit message 使用英文 Conventional Commits。用户当前任务中的明确要求与本文冲突时，以用户要求为准，并在交付时说明偏离了哪一节及原因。

## 事实来源

按以下顺序确认需求和技术决定，不用通用经验覆盖项目约定：

1. 用户在当前任务中的明确要求。
2. [CONTEXT.md](./CONTEXT.md) 中的领域术语。
3. [产品及技术设计文档](./docs/产品及技术设计文档.md) 中的产品行为、技术基线和验收要求。
4. [ADR](./docs/adr/) 中已经确认的平台和动画选型。
5. 仓库代码、配置、测试和锁文件；它们是实现事实。
6. Flutter、Dart、Android 和所用依赖的官方文档及本地源码。

产品行为与技术实现冲突时，先保证产品行为，再检查相关 ADR 是否需要修订。新的领域术语写入 `CONTEXT.md`；已经拍板、难以逆转并会长期约束实现的技术决定写入短 ADR。不要让决定只存在于聊天记录。

非平凡结论应说明证据状态：`[已验证]` 表示实际执行并检查结果或直接读到仓库事实，`[推断]` 表示根据现有事实推出，`[待验证]` 表示仍需实验。静态检查通过不等于功能正确，只有执行对应行为并核对结果后才能写“已验证”。

## 当前可用命令

Flutter 工程已初始化并锁定稳定版（`.flutter-version`），`pubspec.lock` 和 Gradle wrapper 已提交。以下命令均已在本机验证；常用入口在根目录 `Makefile`：

```bash
make run            # 构建 debug APK，安装并启动到 USB 真机（DEVICE=<serial> 可指定设备）
make run-attach     # flutter run 附加到真机（热重载）
make install        # 只安装已构建的 debug APK
make uninstall      # 卸载
make check          # format + analyze + test
make test-device    # 真机集成测试（横屏设备）
make build-debug / make build-release

# Makefile 包装的原始命令：
flutter pub get
dart format --set-exit-if-changed lib test integration_test
flutter analyze
flutter test
flutter test integration_test -d <device-id>   # 真机集成测试（横屏设备）
flutter build apk --debug
flutter build apk --release
```

真机集成测试覆盖 I01、I02、I03、I05、I08；I04（转竖屏）无法在真机注入 metrics 变化，I06（返回关闭 Activity）会终止测试进程，I07（飞行模式）需要 adb 控制，这三项由 Widget 测试和真机用例 A07、A09、A10 覆盖。

文档中的 Mermaid 图优先实际渲染。仓库或本机没有渲染工具时，检查代码围栏、图类型、节点和图文一致性，并在交付中说明尚未完成渲染验证。

<!-- CODEGRAPH_START -->
## CodeGraph

仓库根目录存在 `.codegraph/` 时，在 grep/find 或逐文件阅读前先用 CodeGraph 理解和定位代码：

- MCP 工具可用时，优先使用 `codegraph_explore` 回答代码问题；用 `codegraph_node` 读取具体符号、调用方或带行号文件。
- Shell 始终可以使用：`codegraph explore "<符号或问题>"` 和 `codegraph node <符号或文件>`。

没有 `.codegraph/` 时跳过。是否建立索引由用户决定，不要自行初始化。
<!-- CODEGRAPH_END -->

## 产品边界

- 首版只构建可侧载的 Flutter Android APK，最低 Android 8.0（API 26）；不做 iOS、应用商店或远程素材更新。
- App 打开即锁定横屏（ADR 0003），直接进入检查室；竖屏门禁保留为纵深防御。不增加标题页、菜单、设置、账号、埋点、广告或付费入口。
- 屏幕上的卡通小孩是固定角色，不是正在观看的真实小孩。禁止调用相机、传感器或其他数据制造“正在扫描你”的误解。
- 检查不是问诊。界面不展示病名、器官标注、医学报告或针对真实小孩的结论。
- 业务状态只有 `ready`、`scanning` 和 `result`。竖屏提示是显示门禁，不是第四个业务状态。
- 扫描从“开始扫描”或“再看一次”触发，播放期间普通点击无效。动画结束后必须显示并播放洗手提示。
- 洗手提示原文固定为：“不洗手就吃东西，肚子里会长虫子。快去洗手！”文字与配音逐字一致。
- 系统返回先停止副作用再关闭 Activity。进入后台，或在 `scanning`、`result` 时转成竖屏，会中断当前检查并停止动画和全部音频；回到前台横屏后显示检查室。

产品范围变化时，先更新产品及技术设计文档和验收用例，再改代码。不要把新入口、文案、权限或数据采集当作实现细节直接加入。

## 架构边界

- 首版是单路由、纯本地、内存状态的 Flutter 应用。不要引入后台、网络层、数据库、通用状态管理框架、路由框架或依赖注入容器。
- `ExamCoordinator` 是检查状态和副作用编排的唯一写入口。Widget 只渲染只读状态并转发用户、动画和生命周期事件。
- App 在 AndroidManifest 锁定 `sensorLandscape`（ADR 0003），横屏自动生效。`OrientationGate` 独立处理方向并保留：若撤销锁定，门禁立即可用；不能用锁屏掩盖竖屏适配缺陷（门禁有独立测试）。
- `ExamAudio` 隐藏本地播放器、循环、停止和资源切换。生产实现和测试替身都从该接口进入；Widget 不直接持有 `AudioPlayer`。
- 扫描底音、虫子音效和洗手配音使用独立播放器，避免互相打断或叠音。`stopAll` 必须可重复调用并吞并底层停止错误。
- Lottie 完成回调是正常结束条件，实际动画时长加 1 秒的 watchdog 只做卡死兜底。不要用固定 12 秒计时器代替完成回调。
- 每轮扫描使用递增 `runId` 丢弃上一轮迟到的动画、音效和计时回调。
- 资源全部打进 APK。运行时不下载替代资源，不传远程 URL，不从共享存储读取素材。

模块应把复杂行为藏在窄 interface 后。不要机械增加 controller/service/repository 透传层，也不要为只有一个固定实现的代码预设可替换 seam。

## 隐私和内容安全

- Manifest 不声明 `INTERNET`，也不申请相机、麦克风、定位、蓝牙、通知、相册或存储权限。
- 不加入统计、广告、崩溃上传、远程配置或在线日志 SDK。调试日志不得包含签名密码、密钥、设备原始标识或本机文件路径。
- 业务代码不保存用户行为、检查次数或完成状态。重开 App 一律从 `ready` 开始。
- 发布前检查合并后的 Manifest 和 APK 内容，不能只检查源码 Manifest 或 `pubspec.yaml`。
- 签名 keystore、密码、真实 `key.properties` 和含私密路径的配置不进 Git。正式 `applicationId` 和签名一经对外发包不得随意更换。
- 虫子保持圆钝、卡通、有点恶心但不恐怖；禁止尖牙、伤口、血液、排泄物和写实寄生虫纹理。
- 正式素材必须记录来源、作者和许可。设计工具中能预览不等于 Flutter 真机可用。

不要把教育演示描述为医学检查，也不要声称 App 能识别小孩是否洗手、是否感染或身体里是否真的有虫子。

## Flutter 与 Dart 编码规范

- Flutter SDK 和依赖版本必须固定并提交锁文件。升级 `lottie`、`audioplayers`、Android Gradle Plugin 或 SDK 后，重新跑正式素材、生命周期和 release 构建测试。
- 禁止在 Widget `build` 中启动音频、动画、计时器、状态迁移或 `abort`。方向变化通过 `WidgetsBindingObserver.didChangeMetrics` 去重后发送事件。
- `AnimationController`、播放器、timer、observer 和 stream subscription 都要有明确所有者，在中断和 `dispose` 时释放。
- 异步回调更新 Widget 前检查生命周期；旧 `runId`、已销毁对象或非当前状态的回调直接丢弃。
- 错误显式处理。音频错误按设计静默降级，Lottie 加载失败则进入资源错误状态并禁用扫描入口；不能用空 `catch` 隐藏缺陷。
- 依赖通过构造参数传入。测试使用 fake 时跨同一个 interface，不为测试另开后门或全局单例。
- 文案和资源路径集中定义，不在多个 Widget 中复制。固定洗手文案变更时同时核对配音、测试和 `CONTEXT.md`。
- 平台类型留在 Android 壳或 adapter 内。检查状态模块不依赖 `Activity`、Manifest 或具体播放器类型。

## 界面和素材

- 横屏业务内容使用居中的 16:9 舞台和 `BoxFit.contain`。20:9 手机左右留边，4:3 平板上下留边，不裁切或拉伸卡通小孩。
- 根界面使用 `SafeArea`。按钮和文字不能放进挖孔、圆角或系统手势区。
- 主按钮最小可点击区域为 160 × 64 dp，文字不小于 22 sp；系统字体放大到 1.3 倍时不能截断固定文案和按钮。
- 按钮、提示文案和错误信息由 Flutter 绘制，不烧进背景图或 Lottie。
- `scan.json` 首版使用 1920 × 1080、30 fps 的全矢量内容，不引用未登记的外部位图。动画制作工具的效果要以 Flutter 真机播放为准。
- 素材文件名、格式、时长、音效点和目录遵守产品及技术设计文档。更改素材契约时同步修改 `pubspec.yaml`、测试和文档。

不得为了让 Golden 测试通过而拉伸素材、隐藏溢出或缩小按钮到设计下限以下。

## 测试与审查

非平凡任务按“边界复述 → 方案 → 实现 → 两轮自审 → 交付”推进。缺失信息会改变方向时，一次只问一个问题；能从仓库或官方资料确认的内容直接查，不把调查工作交给用户。

两轮自审都要实际读取 `git diff`：

1. 产品正确性与安全：状态迁移、重复点击、迟到回调、资源失败、方向、前后台、返回、音频停止、权限、日志和文案。
2. 可维护性与性能：模块 interface、所有权、异步取消、重复、布局尺寸、Lottie 性能、音画同步、测试覆盖和文档同步。

发现问题当场修复，不用 TODO/FIXME 代替任务范围内的完成。新增或修改以下内容时必须有测试：

- `ExamCoordinator` 的公开事件和状态迁移；
- 动画完成、watchdog、`runId` 和虫子音效触发；
- 音频 `stopAll`、重复点击和连续重播；
- 竖屏门禁、四类基线尺寸、系统字体 1.3 倍和结果文案；
- `paused`、`hidden`、返回和横竖屏切换。

单元测试使用可控时钟或 fake 动画，不真实等待 12 秒。集成测试可以使用缩短动画的测试构建，但至少一次候选发布验收必须使用正式时长、正式素材和真机。没有目标设备时，性能结论标记为 `[待验证]`，不能根据模拟器结果宣称低端机通过。

## Git

- 不自动提交、推送、force push、打 tag 或合并分支；只有用户明确要求时执行对应动作。
- 提交前检查当前分支、`git status`、完整暂存 diff 和 `git diff --cached --check`，不带入用户的无关改动。
- Commit 使用英文 Conventional Commits：`type(scope): Imperative summary`。文档用 `docs`，构建用 `build`，测试用 `test`，维护用 `chore`；一个提交只表达一个目的。
- 禁止通过删除测试、放宽断言、跳过检查或改写历史掩盖失败。除非用户明确指定并确认目标，不使用破坏性 Git 命令。
- Push 被拒绝时先获取远端状态并说明分歧，不 force push。

## 文档

`docs/AGENTS.md` 约束 `docs/` 下的设计文档，修改这些文件时必须一并遵守。事实、开发默认值和待确认项分开；技术选择写明依据、代价和重新评估条件。关系、时序或状态仅在文字难以核对时使用 Mermaid。

设计决定变化时同步检查：

- `CONTEXT.md`：产品术语和禁止混用的近义词。
- `docs/产品及技术设计文档.md`：产品范围、交互、架构、素材契约、测试和验收。
- `docs/adr/`：已拍板并长期约束实现的平台或技术决定。
- `AGENTS.md`：当前命令、架构边界和仓库级开发约定。

不要编造 API、文件路径、行号、commit hash、依赖版本、benchmark 或设备兼容结论。不确定内容写入待确认项，并说明验证方法和影响范围。

## 常见错误

- 用锁定横屏掩盖竖屏适配缺陷：锁屏是产品决定（ADR 0003），门禁 Widget 和测试仍然独立存在并覆盖竖屏行为。
- 把竖屏提示塞进 `ExamPhase`，让设备方向和检查生命周期争用同一状态机。
- 在 Widget `build` 中播放音频、启动 timer 或调用 `abort`，造成重建时重复触发。
- 用固定 12 秒计时器判断扫描完成，忽略 Lottie 实际时长和完成回调。
- 复用一个播放器播放底音、虫子音效和配音，造成截断、叠音或退出后残留。
- 把普通点击当成扫描跳过、暂停或隐藏入口，偏离首版交互。
- 把按钮和洗手文案烧进 Lottie，导致适配、文字缩放和后续改文案困难。
- 把关闭 Activity 写成“杀死进程”，或依赖进程销毁停止音频。
- 因依赖默认 Manifest 而意外带入网络或其他权限，却没有检查合并产物。
- 使用相机、真实人体画面或诊断措辞，让固定卡通演示看起来像真实检查。
