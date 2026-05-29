# DeskMochi Godot 研发计划

Baseline documents:

- `docs/DeskMochi_GDD_and_Roadmap.md`
- `docs/Feasibility_and_M1_Plan.md`

Local Godot:

- `D:\Godot\Godot_v4.6.1-stable_mono_win64\Godot_v4.6.1-stable_mono_win64.exe`
- Verified version: `4.6.1.stable.mono.official.14d19694e`

## 1. 产品与技术结论

DeskMochi 应该先做成一个 Windows-first 的 Godot 桌面宠物原型。第一阶段不追求功能多，而是验证产品灵魂：透明桌面窗口里有一个可拖拽、可戳按、会回弹、手感软糯的麻糬。

技术路线采用：

- Godot 4.6.1 负责桌宠窗口、2D 渲染、软体交互、动画、轻量 UI。
- GDScript 负责 M1 的快速迭代。
- C#/.NET 或 Rust helper service 作为 M3 之后的系统监听补充，不进入 M1。
- Godot 原生透明窗口与鼠标穿透接口优先，不优先移植 Unity `UniWindowController`。

## 2. 总体研发原则

### 2.1 产品原则

- 先手感，后功能。
- 先桌宠主体，后效率面板。
- 先本地单机，后平台分发。
- 所有生产力功能都必须服务“陪伴感”，不能把桌宠变成普通任务管理器。

### 2.2 架构原则

- 避免 Godot Autoload 单例承载业务核心。
- 根场景持有状态，依赖显式传递。
- 业务状态和渲染表现分离。
- 单向数据流：Input -> Simulation -> Presentation -> Effects。
- 尽量使用扁平模块和数据结构，避免深继承树。
- M1 不做过度抽象，只保留能支撑 M2/M3 的清晰边界。

### 2.3 技术边界

Godot 负责：

- 透明、无边框、置顶桌面窗口。
- 鼠标穿透区域。
- 麻糬主体渲染与形变。
- 拖拽、戳按、下落、回弹。
- 轻量 UI、动画、粒子、音效。

外部 helper service 未来负责：

- 全局键盘频率监听。
- Git push 或仓库事件监听。
- AI Agent token 日志解析。
- 系统托盘、自启动、深层 OS 集成。

## 3. Godot 技术方案

### 3.1 窗口方案

M1 使用 Godot 原生窗口能力：

- `Window.borderless = true`
- `Window.always_on_top = true`
- `Window.transparent = true`
- `Viewport.transparent_bg = true`
- `DisplayServer.window_set_mouse_passthrough(...)`

策略：

- 窗口保持透明、无边框、置顶。
- 麻糬主体周围生成一个近似轮廓 polygon。
- polygon 内部接收鼠标事件，外部穿透到桌面。
- M1 使用简化 polygon，不做像素级 alpha hit-test。

Fallback：

- 如果 Godot 原生透明或穿透在 Windows 实测不稳定，再考虑 Windows 专用 GDExtension 或 C# P/Invoke。
- Unity `UniWindowController` 的思路可以作为 fallback 参考，但不作为第一版依赖。

### 3.2 软体方案

M1 不直接做复杂真实柔体。采用“简化物理 + 视觉柔体”：

- `MochiState` 存储中心位置、速度、拖拽状态、形变参数。
- 轮廓由若干控制点生成，控制点受拖拽、戳按、速度影响。
- 渲染层根据控制点绘制身体或驱动 mesh。
- 回弹由弹簧阻尼参数实现。

第一版形变目标：

- 拖拽时身体被拉伸。
- 快速移动时出现惯性压缩。
- 鼠标戳按位置产生局部凹陷。
- 松手后有一到两次软弹回弹。

### 3.3 状态机

M1 状态：

- `Idle`：静置呼吸、轻微晃动。
- `Hovered`：鼠标靠近或进入可交互区域。
- `Dragged`：被拖拽移动。
- `Poked`：被点击或短按。
- `Falling`：释放后受重力/惯性落下。
- `Settled`：落地或运动收束后的恢复过渡。

状态机只产出数据，不直接播放动画。动画由 Effects/Presentation 根据状态变化触发。

### 3.4 初始工程结构

建议结构：

```text
DeskMochi/
  project.godot
  scenes/
    app/
      App.tscn
    mochi/
      MochiView.tscn
  scripts/
    app/
      app.gd
      app_state.gd
    input/
      input_frame.gd
      input_collector.gd
    simulation/
      mochi_state.gd
      mochi_simulation.gd
      mochi_state_machine.gd
    presentation/
      mochi_view.gd
      mochi_mesh_renderer.gd
      window_controller.gd
    effects/
      effect_queue.gd
      mochi_effects.gd
    persistence/
      user_settings.gd
  assets/
    sprites/
    audio/
    shaders/
  docs/
```

M1 可以先不创建所有文件，但目录边界要从一开始存在。

## 4. Roadmap 整合版

### Phase 0: 项目启动与技术验证

目标：证明 Godot 可以承担 DeskMochi 的桌宠底座。

任务：

- 初始化 Godot 工程。
- 配置 Windows-first 项目设置。
- 验证 Godot 4.6.1 可以从命令行启动项目。
- 实现透明、无边框、置顶窗口。
- 验证鼠标穿透 polygon。
- 记录窗口方案技术决策。

验收：

- 启动后看到透明背景窗口。
- 窗口可置顶。
- polygon 外部点击能穿透到桌面或下层窗口。

### Phase 1: 基础架构与软体核心 (M1)

目标：做出一个可玩的麻糬原型。

任务：

- 建立 Input -> Simulation -> Presentation -> Effects 单向数据流。
- 实现 `MochiState` 和基础状态机。
- 实现临时圆形/椭圆形麻糬身体。
- 实现拖拽移动。
- 实现戳按凹陷。
- 实现回弹与惯性形变。
- 更新 mouse passthrough polygon 贴合主体轮廓。
- 增加基础 idle 呼吸动画。
- 增加简易性能开关：空闲降帧或降低更新频率。

验收：

- 麻糬可以被拖拽。
- 戳按有局部反馈。
- 松手有软弹回弹。
- 透明区域不会挡住桌面操作。
- 代码结构清晰分层，没有业务核心单例。

### Phase 2: UI 组件与自定义化 (M2)

目标：开始形成“陪伴 + 轻生产力”的最小闭环。

任务：

- 实现极简控制面板。
- 番茄钟：开始、暂停、重置、完成提醒。
- ToDo：新增、完成、删除、持久化。
- Focus mode：番茄钟运行时切换安静状态。
- 自定义插槽系统 V1：面部、头顶两个 slot。
- 支持本地图片加载到 slot。
- 用户偏好与任务状态持久化到本地 JSON。

验收：

- 可以完成一次番茄钟专注流程。
- ToDo 数据重启后仍保留。
- 至少一个外部图片能挂载到麻糬身上。

### Phase 3: 数据监听集成 (M3)

目标：把开发者工作流数据转化为宠物反馈。

任务：

- 设计 Godot 与 helper service 的本地通信协议。
- 实现 helper service 原型。
- 键盘输入频率监听：只输出频率，不记录具体按键内容。
- Git 事件监听：先支持指定仓库目录，检测 push 后触发事件。
- AI token 日志解析：先支持本机 Codex/Agent 日志的可配置路径。
- Godot 端事件映射到状态、动画、粒子。

验收：

- 快速打字会触发能量/星星反馈。
- Git push 后触发庆祝动画。
- Token 消耗增长能触发“充能”类表现。
- helper service 不阻塞 Godot 主进程。

### Phase 4: 性能打磨与分发准备 (M4+)

目标：让 DeskMochi 可以长期常驻桌面。

任务：

- Profile idle、拖拽、粒子、UI 打开时的 CPU/GPU 占用。
- 优化空闲状态更新频率。
- 优化 mesh/polygon 更新频率。
- 增加设置页：开机启动、置顶、穿透、动画强度、性能模式。
- 增加默认形象和表现动画。
- 准备 Windows 打包和安装流程。
- 评估 Steam SDK 或其他分发平台接入。

验收：

- 静置和失焦状态资源占用可接受。
- 普通用户可以安装、启动、退出、配置。
- 打包产物包含必要运行时和资源。

## 5. 立即执行顺序

### Step 1: 初始化 Godot 工程

创建最小 Godot 项目：

- `project.godot`
- `scenes/app/App.tscn`
- `scripts/app/app.gd`
- `scripts/presentation/window_controller.gd`

目标不是一次写完架构，而是让 Godot 项目能启动、能看到一个透明窗口。

### Step 2: 透明窗口 spike

先只做窗口：

- 启动透明背景。
- 无边框。
- 置顶。
- 固定初始窗口大小。
- 显示一个临时半透明圆形麻糬。
- 手工设置一个圆形近似 polygon，验证外部穿透。

这是最高风险验证点，要最早做。

### Step 3: 输入与状态骨架

加入：

- `InputFrame`
- `MochiState`
- `MochiSimulation`
- `MochiView`

让每一帧都是：

```text
collect input -> update state -> render state -> update window passthrough
```

### Step 4: 软体手感 V1

加入：

- 拖拽。
- 戳按。
- 速度影响形变。
- 弹簧阻尼回弹。

目标是先让手感成立，视觉可以很粗。

### Step 5: M1 验收与记录

写下：

- 窗口透明方案是否稳定。
- polygon 穿透是否足够。
- 软体方案是否继续沿用。
- 是否需要 C# 或 GDExtension。

## 6. 风险与对策

| 风险 | 影响 | 对策 |
| --- | --- | --- |
| Godot 透明窗口在某些 Windows 环境不稳定 | M1 桌宠底座受阻 | 先 spike；失败后做 Windows native fallback |
| 鼠标穿透 polygon 不够精细 | 点击区域不自然 | M1 用简化轮廓；M2 再做动态轮廓或局部 hit-test |
| 真柔体物理调参过慢 | 拖慢核心体验验证 | M1 使用视觉柔体，不做真实柔体 |
| GDScript 后期系统能力不足 | M3 集成困难 | 系统监听放到 helper service |
| 功能扩张太快 | 核心手感被稀释 | M1 只做宠物主体，不做 ToDo/Git/Token |

## 7. 推荐当前决策

- 第一版只承诺 Windows。
- M1 使用 Godot 4.6.1 + GDScript。
- M1 不使用 Unity `UniWindowController` 或 native DLL。
- M1 不接 C# helper。
- M1 不做正式 UI，不做生产力功能。
- M1 用程序绘制/占位形象，等手感确认后再替换美术。

## 8. 下一次开发任务

下一次实际编码建议直接执行：

1. 初始化 Godot 项目。
2. 创建透明置顶窗口。
3. 画出临时麻糬主体。
4. 验证鼠标穿透 polygon。
5. 跑一次 Godot 启动验证。

完成后再进入拖拽和软体形变。
