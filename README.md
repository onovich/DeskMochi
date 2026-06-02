# DeskMochi

DeskMochi is a Godot-based desktop companion prototype: a soft mochi pet that lives in a transparent, borderless, always-on-top Windows window and reacts to visible-body clicks, drags, productivity state, and local helper events.<br/>**DeskMochi 是一个基于 Godot 的桌面摆件原型：一只柔软的麻薯宠物，运行在 Windows 透明、无边框、置顶窗口中，并响应可见主体点击、拖拽、效率状态和本地 helper 事件。**

The project is currently an editor-run prototype, not a finished packaged application. Windows export configuration exists, but export templates and final packaging are still pending.<br/>**当前项目仍是通过编辑器运行的原型，不是已经完成打包的应用。仓库中已有 Windows 导出配置，但导出模板和最终打包仍待完成。**

## Status

- Phase 0 and the Godot project foundation are validated: the project loads in Godot 4.6.1 Mono and the short window smoke passes on the Windows test machine.<br/>**Phase 0 和 Godot 项目基础已验证：项目可在 Godot 4.6.1 Mono 中加载，短窗口 smoke 已在 Windows 测试机通过。**
- M1 soft-body interaction is implemented but still needs manual handfeel acceptance after the latest drag/input fixes.<br/>**M1 软体交互已实现，但在最近的拖拽和输入修正后，仍需要手动验收手感。**
- M2 productivity and customization foundations exist: Pomodoro, ToDo, image slots, persistence, compact panel, and performance modes.<br/>**M2 效率和自定义基础已存在：番茄钟、ToDo、图片槽位、持久化、紧凑面板和性能模式。**
- M3 helper integration exists as a local .NET service that emits keyboard-frequency, Git-like, and token-usage events over localhost.<br/>**M3 helper 集成已存在，是一个本地 .NET 服务，通过 localhost 输出键盘频率、类似 Git 的事件和 token 使用事件。**
- M4 packaging has started with an export preset and readiness check, but real Windows packaging is not complete yet.<br/>**M4 打包工作已开始，包含导出 preset 和 readiness 检查，但真实 Windows 包体尚未完成。**

## Features

- Transparent, borderless, always-on-top Godot window with body-shaped input masking.<br/>**透明、无边框、置顶的 Godot 窗口，并使用主体形状的输入遮罩。**
- Visible mochi body supports poke feedback, immediate dragging, falling, bounce, squash/stretch, and handfeel presets.<br/>**可见麻薯主体支持点击反馈、即时拖拽、下落、回弹、挤压拉伸和手感预设。**
- Compact control panel opens with `F2` or the in-body `...` button.<br/>**紧凑控制面板可通过 `F2` 或麻薯身上的 `...` 按钮打开。**
- Pomodoro, ToDo, image-slot customization, performance modes, and local persistence are implemented in prototype form.<br/>**番茄钟、ToDo、图片槽位自定义、性能模式和本地持久化已以原型形式实现。**
- Background clicks are not a product interaction; smoke testing focuses on the visible mochi and panel controls.<br/>**背景点击不是产品交互；smoke 测试聚焦可见麻薯和面板控件。**

## Requirements

- Windows development environment.<br/>**Windows 开发环境。**
- Godot `4.6.1-stable_mono_win64` installed at `D:\Godot\Godot_v4.6.1-stable_mono_win64` for the current scripts.<br/>**当前脚本要求 Godot `4.6.1-stable_mono_win64` 安装在 `D:\Godot\Godot_v4.6.1-stable_mono_win64`。**
- .NET SDK capable of building `net10.0` for `helper/DeskMochi.Helper`.<br/>**需要可构建 `helper/DeskMochi.Helper` 中 `net10.0` 项目的 .NET SDK。**

## Validate

Run the configured project validation wrapper from the repository root:<br/>**在仓库根目录运行已配置的项目验证 wrapper：**

```powershell
C:\Users\Administrator\.codex\skills\project-ops-workflow\scripts\ops\Validate.cmd
```

The validation sequence checks the Godot environment, restores and builds the helper, validates Godot loading, runs state roundtrip checks, tests the helper service, parses workflow scripts, and performs a short Godot window smoke.<br/>**验证流程会检查 Godot 环境、还原并构建 helper、验证 Godot 加载、运行状态往返检查、测试 helper 服务、解析工作流脚本，并执行一次短 Godot 窗口 smoke。**

## Run

Run the prototype directly with Godot:<br/>**可以直接用 Godot 运行原型：**

```powershell
D:\Godot\Godot_v4.6.1-stable_mono_win64\Godot_v4.6.1-stable_mono_win64_console.exe --path D:\LabProjects\DeskMochi --log-file D:/LabProjects/DeskMochi/.godot_runtime/logs/godot-window.log
```

Use the manual smoke launcher when the behavior needs human observation:<br/>**需要人工观察行为时，使用 manual smoke 启动器：**

```text
StartManualSmoke.cmd
```

Stop the manual smoke session with:<br/>**使用下面的启动器停止 manual smoke 会话：**

```text
StopManualSmoke.cmd
```

Do not start manual smoke while a fullscreen game, capture-sensitive application, or GPU-heavy workload is running. The prototype uses a transparent always-on-top Godot/OpenGL window and can disturb fragile fullscreen or overlay environments.<br/>**不要在全屏游戏、采集敏感应用或 GPU 高负载任务运行时启动 manual smoke。该原型使用透明置顶的 Godot/OpenGL 窗口，可能干扰脆弱的全屏或覆盖层环境。**

## Helper Service

The helper prototype lives under `helper/DeskMochi.Helper` and exposes local HTTP endpoints on `127.0.0.1:8765` when launched by the smoke workflow or manually.<br/>**helper 原型位于 `helper/DeskMochi.Helper`，由 smoke 工作流或手动启动后，会在 `127.0.0.1:8765` 暴露本地 HTTP 端点。**

```powershell
dotnet run --project helper\DeskMochi.Helper\DeskMochi.Helper.csproj -- --config helper\deskmochi-helper.config.example.json
```

Supported endpoints include `/health`, `/events?last_id=0`, and `/shutdown`.<br/>**支持的端点包括 `/health`、`/events?last_id=0` 和 `/shutdown`。**

## Repository Guide

- `project.godot`, `scenes/`, and `scripts/` contain the Godot prototype.<br/>**`project.godot`、`scenes/` 和 `scripts/` 包含 Godot 原型。**
- `helper/` contains the local .NET helper service.<br/>**`helper/` 包含本地 .NET helper 服务。**
- `tools/` contains validation, smoke, measurement, and export-readiness scripts.<br/>**`tools/` 包含验证、smoke、资源测量和导出 readiness 脚本。**
- `docs/` contains the synced design roadmap, development plan, runbook, checklists, decisions, and smoke results.<br/>**`docs/` 包含已同步的设计 roadmap、开发计划、runbook、检查清单、决策记录和 smoke 结果。**

## Notes

- Transparent background space is not an interaction surface; only the visible mochi body and panel controls are part of the current acceptance path.<br/>**透明背景区域不是交互面；当前验收路径只包含可见麻薯主体和面板控件。**
- The control panel can temporarily request full-window input, but click, poke, and drag should keep the background transparent.<br/>**控制面板可以临时请求整窗输入，但点击、poke 和拖拽期间应保持背景透明。**
- Manual runtime acceptance is still required before claiming the prototype is ready for broader daily use.<br/>**在声明该原型适合更广泛的日常使用之前，仍需要完成手动运行时验收。**
