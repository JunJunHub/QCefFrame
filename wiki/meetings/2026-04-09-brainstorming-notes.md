# 会话决策记录

**日期**: 2026-04-09
**类型**: 头脑风暴 / 项目启动
**参与者**: 用户 + Claude

---

## 项目背景

用户希望开发一个类似 Electron 的跨平台桌面应用框架，但需要支持 ARM 嵌入式平台。

---

## 需求分析

### 核心需求

| 需求项 | 具体内容 |
|--------|----------|
| 技术栈 | Qt + CEF (Chromium Embedded Framework) |
| 目标平台 | ARM64 嵌入式 (RK3568) + 桌面平台 (Win/Mac/Linux x64) |
| 许可证约束 | 仅使用 Qt 非商业模块 (LGPL) |
| 性能约束 | 2GB 内存、页面加载 ~2s |
| 功能需求 | 模块化裁剪 CEF，可配置保留/移除 WebRTC |

### 硬件参考

- **CPU**: RK3568 (4核 Cortex-A55 @ 2.0GHz)
- **内存**: 2GB
- **操作系统**: Buildroot 定制 Linux

---

## 决策记录

### 决策 1：框架形态

**问题**: 框架应该提供什么级别的抽象？

**选项**:
- A. CEF 集成库 - 仅提供 Qt 控件封装
- B. 类 Electron 完整框架 - 提供完整工具链
- C. 中间路线 - 复用 QCefView + 补充框架层功能

**决策**: **选项 C**

**理由**:
- QCefView 已经成熟地解决了 Qt-CEF 集成问题
- 避免重复造轮子，专注框架层能力
- CEF 裁剪作为独立模块处理，不依赖 QCefView

---

### 决策 2：Qt 模块支持

**问题**: 支持 QWidget 还是 Qt Quick/QML？

**决策**: **两者都支持**

**理由**:
- QWidget 适合传统桌面/工业设备界面
- QML 适合现代动态界面、触屏交互
- 扩大框架适用范围

---

### 决策 3：是否基于现有项目

**问题**: 从零开始还是基于现有项目？

**决策**: **基于 QCefView 扩展**

**理由**:
- QCefView (733+ stars) 是最相关的开源项目
- 活跃维护，最新版本 v2025.12.28
- 支持 Windows/macOS/Linux (x86_64)
- 可扩展支持 linux-arm64

---

### 决策 4：JS-C++ 互操作 API 风格

**问题**: JavaScript 和 C++ 之间如何通信？

**决策**: **复用 QCefView 已有机制 (QCefQuery / QCefEvent)**

**理由**:
- QCefView 已提供成熟的 JS-C++ 通信机制
- QCefQuery: JS → C++ 查询请求，支持异步回调
- QCefEvent: C++ → JS 事件触发
- 无需重新设计，降低开发成本

**API 使用方式**:
```cpp
// C++ 端
connect(view, &QCefView::cefQueryRequest, [](query) {
    query.reply(true, "response");
});

QCefEvent event("eventName");
event.setArguments({arg1, arg2});
view->triggerEvent(event);
```
```javascript
// JavaScript 端
window.cefQuery({request: "action", onSuccess: callback});
window.cefEvent.addEventListener("eventName", callback);
```

---

### 决策 5：部署工具范围

**问题**: 部署工具覆盖哪些平台？

**选项**:
- A. 仅 ARM 嵌入式
- B. 跨平台打包 (Win/Mac/Linux x64+ARM)
- C. 嵌入式优先，桌面辅助

**决策**: **选项 A + B - 完整跨平台支持**

**理由**:
- 用户需要同时支持嵌入式和桌面端
- 开发调试时需要桌面环境

---

### 决策 6：CEF 裁剪策略

**问题**: 如何裁剪 CEF 以减小体积和资源占用？

**选项**:
- A. 编译时裁剪 - 从源码编译，禁用不需要的功能
- B. 运行时配置 - 使用预编译包，命令行参数禁用
- C. 分层策略 - ARM 编译裁剪，桌面预编译

**决策**: **选项 C - 分层策略**

**理由**:
- ARM 嵌入式资源有限，需要最大程度优化
- 桌面端使用预编译包，降低开发复杂度
- 灵活应对不同场景需求

---

### 决策 7：WebRTC 功能支持

**问题**: 是否需要 WebRTC？

**决策**: **可配置支持**

**要求**:
- WebRTC 是重要功能，需要保留
- 根据功能需要，配置是否保留 WebRTC
- 影响裁剪策略和编译复杂度

---

### 决策 8：嵌入式必须保留的功能

**问题**: 嵌入式端必须保留哪些功能？

**决策**: **WebRTC + 多媒体完整**

**必须功能**:
- WebRTC - 视频通话/直播
- 音频播放
- 页面渲染
- 视频播放 (H.264/H.265)
- WebGL / Canvas 2D

**可禁用功能**:
- PDF 查看器
- 浏览器扩展
- 打印功能

---

### 决策 9：架构方案选择（已变更）

**问题**: 如何组织 QCefView 和新框架的关系？

**选项**:
- A. QCefView 上层扩展 - QCefFrame 作为独立框架依赖 QCefView (Git Submodule)
- B. 基于 CefViewCore 自建 - 自己实现 Qt 集成层
- C. Fork QCefView - 直接在 QCefView 源码基础上开发

**决策**: **选项 C - Fork QCefView**

**理由**:
- QML 支持必须修改核心代码，简单的封装无法解决
- QWidget 无法直接嵌入 Qt Quick 2 场景图，需要实现 OSR 模式
- ARM64 交叉编译需要修改 CMake 配置
- QCefView 官方明确表示无计划支持 QML 和 ARM64
- 直接修改源码更灵活，维护更简单

**QCefView 官方态度**:
- Issue #509: QML 支持请求 → 标记 `noplan`，技术原因：Qt Quick 2 场景图架构不兼容
- Issue #29: ARM64 交叉编译 → 建议用户自行修改 CMake

---

### 决策 10：QML 渲染方案

**问题**: 如何在 QML 中渲染 CEF 内容？

**技术背景**:
- Qt Quick 2 使用 Scene Graph 在 GPU 上渲染
- QWidget 使用传统的 Raster/OpenGL Widget 渲染
- 两者架构不兼容，QWidget 无法直接嵌入 QML

**决策**: **OSR (Off-Screen Rendering) 模式 + 纹理上传**

**实现方案**:
```
CEF Browser → CPU 渲染缓冲区 → OpenGL 纹理 → Scene Graph
```

**技术要点**:
1. 使用 CEF 的 OSR 模式，渲染到 CPU 缓冲区
2. 创建 `QCefQuickItem` (QQuickItem 子类)
3. 重写 `updatePaintNode()` 将缓冲区内容上传为纹理
4. 复用 QCefQuery/Event 通信机制

**优点**:
- 原生 QML 组件，支持 QML 属性和信号
- 可与其他 QML Item 混合使用
- 支持 QML 动画和变换

---

### 决策 11：QML 支持可选化

**问题**: 非 QML 应用是否需要依赖 Qt Quick 模块？

**决策**: **QML 支持作为可选模块**

**实现方案**:
- CMake 选项 `BUILD_QT_QUICK` 控制是否编译 QML 支持
- 默认 `OFF`，仅编译 QWidget 支持
- 非 QML 应用不需要链接 Qt Quick 相关库

**依赖分离**:

| 配置 | Qt 模块依赖 |
|------|-------------|
| 仅 QWidget (默认) | Core, Gui, Widgets |
| QWidget + QML | Core, Gui, Widgets, Quick, QML |

**理由**:
- 嵌入式设备资源有限，减少不必要的依赖
- 核心价值是 ARM64 编译支持，QML 为扩展功能
- 用户可根据需求选择是否启用

---

## 项目命名

**框架名称**: QCefFrame

**命名理由**:
- Q = Qt
- Cef = Chromium Embedded Framework
- Frame = Framework
- 简洁、表意明确

---

## 关键约束

1. **许可证**: 仅使用 Qt 非商业模块 (LGPL)
2. **性能**: RK3568 + 2GB 内存，页面加载 ~2s
3. **平台**: ARM64 嵌入式为首要目标
4. **复用**: 基于 QCefView 扩展，避免重复造轮子

---

## 后续行动

1. Fork QCefView 仓库，重命名为 QCefFrame
2. 添加 ARM64 交叉编译 CMake 配置
3. 实现 QCefQuickItem (OSR 模式 + 纹理上传)
4. 创建 QML 示例应用
5. 开发 CEF Builder 工具支持模块化裁剪
6. 完善打包工具支持跨平台分发

---

## 参考 GitHub 项目

| 项目 | Star | 描述 |
|------|------|------|
| [CefView/QCefView](https://github.com/CefView/QCefView) | 733+ | Qt Widget 封装 CEF，本项目依赖 |
| [CefView/CefViewCore](https://github.com/CefView/CefViewCore) | 131+ | CEF 通用封装库 |
| [qt/qtwebengine](https://github.com/qt/qtwebengine) | 422+ | Qt 官方 WebEngine 模块 |
