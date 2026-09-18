---
name: browser-agent
description: 使用本机共享的真实 Google Chrome、固定 Profile 和 CDP，为 Skill、Python 项目及 AI Agent 提供可自动恢复的浏览器运行环境。适用于网页采集、登录态复用、页面调试和浏览器自动化。
---

# Browser Agent

## 固定入口

所有本机 Skill、Python 项目和 AI Agent 统一使用同一套协议：

```text
macOS 控制入口：~/browser-agent/browser-agent
Windows 控制入口：%USERPROFILE%\browser-agent\browser-agent.cmd
共享 Profile：<browser-agent>/chrome-profile
CDP：http://127.0.0.1:19312
```

不要自行启动临时 Chromium，不要在业务项目中管理 Chrome Profile、CDP 端口或 Chrome 进程。

## 外部项目标准流程

### 1. 保证浏览器在线

```bash
~/browser-agent/browser-agent ensure
```

Windows 对应命令：

```powershell
%USERPROFILE%\browser-agent\browser-agent.cmd ensure
```

`ensure` 会自动处理以下状态：

```text
CDP 正常
  └── 直接复用当前 Chrome

CDP 异常
  ├── 检查共享 Profile 的 Chrome 进程
  ├── 结束异常进程
  ├── 清理运行时锁
  ├── 启动真实 Google Chrome
  └── 等待 CDP 恢复
```

`start` 是 `ensure` 的别名。

### 2. 通过 CDP 连接

Python + Playwright 示例：

```python
import subprocess
from pathlib import Path

from playwright.sync_api import sync_playwright


browser_agent = Path.home() / "browser-agent" / "browser-agent"

subprocess.run(
    [str(browser_agent), "ensure"],
    check=True,
)

with sync_playwright() as playwright:
    browser = playwright.chromium.connect_over_cdp(
        "http://127.0.0.1:19312"
    )
    context = browser.contexts[0]
    page = context.new_page()

    try:
        page.goto("https://example.com")
        # 业务逻辑
    finally:
        page.close()
```

## 共享浏览器规则

1. 业务项目只创建和关闭自己的 `page`。
2. 不执行 `context.close()`，避免关闭共享 Context。
3. 不执行 `browser.close()`，避免影响其他 Skill 或 Agent。
4. 不调用 `launch()` 或 `launch_persistent_context()` 创建另一套浏览器。
5. 不修改共享 Profile 路径和固定 CDP 端口。
6. 遇到验证码、扫码或账号验证时，让用户在可见 Chrome 中手动处理。
7. 默认不要并发操作同一页面；不同任务应各自创建独立页面。
8. 只有用户明确要求关闭共享浏览器时，才执行 `browser-agent stop`。

## Agent 页面操作

```bash
~/browser-agent/browser-agent ensure
~/browser-agent/browser-agent status
~/browser-agent/browser-agent open "<url>"
~/browser-agent/browser-agent snapshot
~/browser-agent/browser-agent click <ref>
~/browser-agent/browser-agent fill <ref> "<text>"
~/browser-agent/browser-agent screenshot
~/browser-agent/browser-agent disconnect
```

Windows 使用完全相同的子命令，只将入口替换为：

```text
%USERPROFILE%\browser-agent\browser-agent.cmd
```

页面跳转、刷新、弹窗或登录状态变化后，应重新执行 `snapshot`，不要继续使用旧的元素引用。

## 职责边界

```text
browser-agent
  ├── 管理真实 Chrome 生命周期
  ├── 管理共享 Profile
  ├── 检查和恢复 CDP
  ├── 结束异常 Chrome 进程
  └── 对外提供 ensure 接口

业务 Skill / AI Agent
  ├── 调用 ensure
  ├── connect_over_cdp
  ├── 创建自己的 page
  ├── 执行业务逻辑
  └── 只关闭自己的 page
```
