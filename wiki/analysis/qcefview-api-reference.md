# QCefView API 速查表

**版本**: 基于 CEF 142.0.15 / Chromium 142

---

## 1. 初始化流程

```cpp
// main.cpp
#include <QCefContext.h>

int main(int argc, char* argv[]) {
    QApplication app(argc, argv);
    
    // 1. 配置 CEF
    QCefConfig config;
    config.setWindowlessRenderingEnabled(true);  // 启用 OSR
    config.setRemoteDebuggingPort(9000);          // 远程调试端口
    config.setCachePath("/path/to/cache");        // 缓存目录
    config.setBridgeObjectName("CallBridge");     // JS 桥接对象名
    
    // 2. 初始化 CEF 上下文
    QCefContext cefContext(&app, argc, argv, &config);
    
    // 3. 创建主窗口
    MainWindow w;
    w.show();
    
    return app.exec();
}
```

---

## 2. QCefConfig (全局配置)

| 方法 | 说明 | 默认值 |
|------|------|--------|
| `setWindowlessRenderingEnabled(bool)` | 启用 OSR 模式 | true |
| `setStandaloneMessageLoopEnabled(bool)` | 独立消息循环线程 | false |
| `setRemoteDebuggingPort(short)` | 远程调试端口 | 0 (禁用) |
| `setCachePath(QString)` | 缓存目录 | 空 |
| `setBridgeObjectName(QString)` | JS 桥接对象名 | "CefViewClient" |
| `setBuiltinSchemeName(QString)` | 内置协议名 | "CefView" |
| `setLogLevel(LogLevel)` | 日志级别 | DEFAULT |
| `setUserAgent(QString)` | User Agent | 默认 |
| `setSandboxDisabled(bool)` | 禁用沙箱 | true |
| `addCommandLineSwitch(QString)` | 添加命令行开关 | - |
| `addCommandLineSwitchWithValue(key, value)` | 添加命令行参数 | - |

**常用命令行参数**:
```cpp
config.addCommandLineSwitch("use-mock-keychain");
config.addCommandLineSwitch("enable-aggressive-domstorage-flushing");
config.addCommandLineSwitchWithValue("remote-allow-origins", "*");
```

---

## 3. QCefSetting (单浏览器设置)

| 方法 | 说明 | 默认值 |
|------|------|--------|
| `setOffScreenRenderingEnabled(bool)` | 启用 OSR (需全局开启) | 继承全局 |
| `setWindowInitialSize(QSize)` | 初始大小 | 800x600 |
| `setWebGL(bool)` | 启用 WebGL | true |
| `setJavascript(bool)` | 启用 JavaScript | true |
| `setLocalStorage(bool)` | 启用 LocalStorage | true |
| `setDatabases(bool)` | 启用 Database | true |
| `setBackgroundColor(QColor)` | 背景色 | 白色 |
| `setStandardFontFamily(QString)` | 标准字体 | 系统默认 |
| `setDefaultFontSize(int)` | 默认字号 | 系统默认 |

---

## 4. QCefView (浏览器视图)

### 4.1 构造函数

```cpp
// 方式一: 简单构造
QCefView* view = new QCefView(parent);

// 方式二: 带 URL 和设置
QCefSetting setting;
setting.setBackgroundColor(Qt::white);
QCefView* view = new QCefView("https://example.com", &setting, parent);
```

### 4.2 导航方法

| 方法 | 说明 |
|------|------|
| `navigateToUrl(QString)` | 导航到 URL |
| `navigateToString(QString)` | 加载 HTML 内容 |
| `browserReload()` | 刷新页面 |
| `browserStopLoad()` | 停止加载 |
| `browserGoBack()` | 后退 |
| `browserGoForward()` | 前进 |
| `browserCanGoBack()` | 是否可后退 |
| `browserCanGoForward()` | 是否可前进 |
| `browserIsLoading()` | 是否正在加载 |

### 4.3 JavaScript 交互

| 方法 | 说明 |
|------|------|
| `executeJavascript(frameId, code, url)` | 执行 JS (无返回) |
| `executeJavascriptWithResult(frameId, code, url, context)` | 执行 JS (有返回) |
| `triggerEvent(event)` | 发送事件到主帧 |
| `triggerEvent(event, frameId)` | 发送事件到指定帧 |
| `broadcastEvent(event)` | 广播事件到所有帧 |
| `responseQCefQuery(query)` | 响应 JS 查询 |

### 4.4 其他方法

| 方法 | 说明 |
|------|------|
| `browserId()` | 获取浏览器 ID |
| `setOSRFrameRate(int fps)` | 设置 OSR 帧率 |
| `setZoomLevel(double)` | 设置缩放级别 |
| `zoomLevel()` | 获取缩放级别 |
| `showDevTools()` | 打开开发者工具 |
| `closeDevTools()` | 关闭开发者工具 |
| `hasDevTools()` | 是否已打开 DevTools |
| `setAllowDrag(bool)` | 是否允许拖拽 |
| `setPreference(name, value, error)` | 设置浏览器偏好 |

### 4.5 信号

```cpp
// 加载相关
void loadingStateChanged(browserId, isLoading, canGoBack, canGoForward);
void loadStart(browserId, frameId, isMainFrame, transitionType);
void loadEnd(browserId, frameId, isMainFrame, httpStatusCode);
void loadError(browserId, frameId, isMainFrame, errorCode, errorMsg, failedUrl);
void loadingProgressChanged(progress);

// 页面信息
void titleChanged(title);
void addressChanged(frameId, url);
void faviconURLChanged(urls);
void statusMessage(message);

// JS 交互
void cefQueryRequest(browserId, frameId, query);
void invokeMethod(browserId, frameId, method, arguments);
void reportJavascriptResult(browserId, frameId, context, result);

// UI 相关
void draggableRegionChanged(draggableRegion, nonDraggableRegion);
void fullscreenModeChanged(fullscreen);
void consoleMessage(message, level);

// 窗口
void nativeBrowserCreated(QWindow* window);
```

---

## 5. QCefQuery (JS → C++)

### 5.1 C++ 端处理

```cpp
connect(view, &QCefView::cefQueryRequest,
        [](const QCefBrowserId& browserId,
           const QCefFrameId& frameId,
           const QCefQuery& query) {
    
    QString request = query.request();  // 获取请求内容
    qint64 id = query.id();             // 获取查询 ID
    
    // 处理请求...
    if (request == "getUserInfo") {
        query.reply(true, R"({"name":"John","age":25})");
    } else {
        query.reply(false, "Unknown request", 1);
    }
});
```

### 5.2 JavaScript 端发送

```javascript
// 发送查询
window.cefQuery({
    request: JSON.stringify({ action: "getUserInfo", userId: 123 }),
    onSuccess: function(response) {
        console.log("Success:", response);
    },
    onFailure: function(errorCode, errorMessage) {
        console.error("Error:", errorCode, errorMessage);
    }
});
```

---

## 6. QCefEvent (C++ → JS)

### 6.1 C++ 端发送

```cpp
QCefEvent event("onDataUpdate");
event.setArguments({ "item1", 100, true });
view->triggerEvent(event);

// 发送到指定帧
view->triggerEvent(event, frameId);

// 广播到所有帧
view->broadcastEvent(event);
```

### 6.2 JavaScript 端接收

```javascript
// 监听事件
window.cefEvent.addEventListener("onDataUpdate", function(item, count, active) {
    console.log("Received:", item, count, active);
});
```

---

## 7. Frame ID 常量

```cpp
QCefView::MainFrameID  // 主帧
QCefView::AllFrameID   // 所有帧 (用于 broadcastEvent)
```

---

## 8. 本地资源映射

### 8.1 全局映射 (QCefContext)

```cpp
// 映射本地目录
cefContext.addLocalFolderResource("/path/to/web", "https://app.local");

// 映射 zip 文件
cefContext.addArchiveResource("/path/to/resources.zip", "https://assets.local");
```

### 8.2 单实例映射 (QCefView)

```cpp
view->addLocalFolderResource("/path/to/local", "https://custom.local");
view->addArchiveResource("/path/to/archive.zip", "https://archive.local", "password");
```

---

## 9. 下载管理

```cpp
class MyCefView : public QCefView {
protected:
    void onNewDownloadItem(const QSharedPointer<QCefDownloadItem>& item,
                           const QString& suggestedName) override {
        // 允许下载
        item->start("/path/to/save/" + suggestedName);
    }
    
    void onUpdateDownloadItem(const QSharedPointer<QCefDownloadItem>& item) override {
        // 更新进度
        qDebug() << "Progress:" << item->progress();
    }
};
```

---

## 10. 弹窗控制

```cpp
class MyCefView : public QCefView {
protected:
    QCefView* onNewBrowser(const QCefFrameId& sourceFrameId,
                           const QString& url,
                           const QString& name,
                           CefWindowOpenDisposition disposition,
                           QRect& rect,
                           QCefSetting& settings) override {
        // 返回新 QCefView 实例允许弹窗
        // 返回 nullptr 取消弹窗
        return new MyCefView(url, &settings);
    }
    
    bool onNewPopup(const QCefFrameId& frameId,
                    const QString& targetUrl,
                    QString& targetFrameName,
                    CefWindowOpenDisposition disposition,
                    QRect& rect,
                    QCefSetting& settings,
                    bool& disableJavascriptAccess) override {
        // 返回 true 取消弹窗
        // 返回 false 允许弹窗
        return false;
    }
};
```

---

## 11. 完整示例

```cpp
// main.cpp
#include <QApplication>
#include <QCefContext.h>
#include <QCefView.h>

int main(int argc, char* argv[]) {
    QApplication app(argc, argv);
    
    // 配置
    QCefConfig config;
    config.setWindowlessRenderingEnabled(true);
    config.setRemoteDebuggingPort(9000);
    config.setBridgeObjectName("NativeBridge");
    
    // 初始化
    QCefContext context(&app, argc, argv, &config);
    
    // 创建视图
    QCefView* view = new QCefView("https://example.com");
    
    // 连接信号
    QObject::connect(view, &QCefView::titleChanged,
                     [](const QString& title) {
                         qDebug() << "Title:" << title;
                     });
    
    QObject::connect(view, &QCefView::cefQueryRequest,
                     [](const QCefBrowserId&, const QCefFrameId&,
                        const QCefQuery& query) {
                         if (query.request() == "ping") {
                             query.reply(true, "pong");
                         }
                     });
    
    view->resize(800, 600);
    view->show();
    
    return app.exec();
}
```
