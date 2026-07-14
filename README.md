# Browser Agent

这是本机所有 Agent 共用的浏览器控制入口。

无论使用 ChatGPT、Codex、Claude Code 还是 OpenClaw，只要用户说“参考 `~/browser-agent` 做浏览器探测”，都使用这里的同一个 Chrome Profile。

前提是 Agent 能在这台 Mac 上执行本地命令；纯云端、没有 DevSpace 或本机 Shell 权限的 Agent 无法直接控制该浏览器。

## 固定约定

```text
目录：~/browser-agent
Chrome Profile：~/browser-agent/chrome-profile
CDP：http://127.0.0.1:19312
控制入口：~/browser-agent/browser-agent
```

`~/browser-agent` 是固定入口，实际链接到：

```text
~/.openclaw/workspace/browser-agent
```

因此 ChatGPT/DevSpace、Codex 和 OpenClaw 都能访问同一套文件。

Chrome 登录状态、Cookie、本地存储和浏览器配置保存在 `chrome-profile/`。Agent 连接结束不会关闭 Chrome，下次可继续连接同一实例。

## 保证浏览器在线

```bash
~/browser-agent/browser-agent ensure
```

`ensure` 是给所有 Agent、Skill 和本地项目使用的统一入口：

```text
检查 CDP 是否正常
    ├── 正常：直接复用当前 Chrome
    └── 异常：
          检查共享 Profile 进程
              ├── 存在异常进程：结束旧进程
              └── 不存在：继续
          清理 Chrome 运行时锁
          启动真实 Google Chrome
          等待 CDP 恢复
```

`start` 现在是 `ensure` 的别名。打开的 Chrome 是专用 AI Profile。首次使用时，由用户手动登录淘宝、天猫、京东等网站，以后复用该登录状态。

## Agent 标准操作

```bash
# 保证共享 Chrome 已在线
~/browser-agent/browser-agent ensure

# 查看状态
~/browser-agent/browser-agent status

# 打开或切换网页
~/browser-agent/browser-agent open "https://www.baidu.com"

# 获取最新页面结构
~/browser-agent/browser-agent snapshot

# 根据 snapshot 返回的 ref 操作
~/browser-agent/browser-agent click e12
~/browser-agent/browser-agent fill e20 "测试内容"

# 截图
~/browser-agent/browser-agent screenshot

# 只断开 Agent，不关闭 Chrome
~/browser-agent/browser-agent disconnect
```

下次 Agent 再执行任意页面命令时，会自动重新连接 `127.0.0.1:19312`。

## 外部 Skill / Python 项目接入

外部项目不负责 Chrome Profile、进程和端口生命周期，只做两步：

```python
import subprocess
from pathlib import Path

from playwright.sync_api import sync_playwright

browser_agent = Path.home() / "browser-agent" / "browser-agent"
subprocess.run([str(browser_agent), "ensure"], check=True)

with sync_playwright() as playwright:
    browser = playwright.chromium.connect_over_cdp("http://127.0.0.1:19312")
```

职责划分：

```text
browser-agent
  ├── 固定共享 Profile
  ├── 检查 CDP
  ├── 识别异常 Chrome 进程
  ├── 必要时结束并重启 Chrome
  └── 对外提供 ensure 接口

业务 Skill
  ├── 调用 browser-agent ensure
  ├── connect_over_cdp
  └── 执行页面业务逻辑
```

## 关闭浏览器

只有用户明确要求关闭共享浏览器时才执行：

```bash
~/browser-agent/browser-agent stop
```

平时任务结束不要执行 `stop`，最多执行 `disconnect`。

## Agent 使用规则

1. 浏览器探测统一使用 `~/browser-agent/browser-agent`，不要直接运行 `playwright-cli open`，否则会创建临时浏览器。
2. 操作前先执行最新 `snapshot`；页面跳转、刷新、弹窗变化后重新执行 `snapshot`。
3. 默认同一时间只允许一个 Agent 操作，避免不同 Agent 同时点击同一页面。
4. 不尝试绕过验证码、登录验证或账号安全验证；需要时让用户在可见 Chrome 中手动完成。
5. 截图、页面快照和控制台日志统一保存在 `~/browser-agent/.playwright-cli/`。

不同产品读取约定的位置：

- Codex：`~/browser-agent/AGENTS.md`
- Claude Code：`~/browser-agent/CLAUDE.md`
- ChatGPT/其他本地 Agent：`~/browser-agent/README.md`
- OpenClaw：`~/.openclaw/workspace/skills/browser-control/SKILL.md`

## 多 Agent 会话名

默认 Playwright CLI 会话名是 `browser-agent`。必要时可以临时指定：

```bash
BROWSER_AGENT_SESSION=codex ~/browser-agent/browser-agent snapshot
```

不同会话名仍控制同一个 Chrome Profile。不要并发操作。

## 配置

配置文件：

```text
~/browser-agent/config.env
```

默认使用 macOS Google Chrome 和端口 `19312`。该端口避开了你机器上现有的 `9222` 和其他浏览器自动化端口，不要随意改变 Profile 路径和端口。
