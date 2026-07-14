# Browser Agent Instructions

本目录是跨 Agent 共用的本机浏览器控制约定。

执行任何浏览器探测前：

1. 阅读 `README.md`。
2. 统一调用 `~/browser-agent/browser-agent`。
3. 不直接运行 `playwright-cli open`，不创建临时 Profile。
4. 使用固定 Profile：`~/browser-agent/chrome-profile`。
5. 使用固定 CDP：`http://127.0.0.1:19312`。

标准流程：

```bash
~/browser-agent/browser-agent ensure
~/browser-agent/browser-agent status
~/browser-agent/browser-agent open "<url>"
~/browser-agent/browser-agent snapshot
~/browser-agent/browser-agent click <ref>
~/browser-agent/browser-agent screenshot
```

外部 Skill 或 Python 项目必须先调用 `ensure`，再连接固定 CDP。
`ensure` 会复用正常运行的 Chrome；CDP 不可用且检测到异常 Profile
进程时，会结束旧进程并重新启动。

页面状态变化后重新 snapshot，不复用旧 ref。任务结束不要关闭 Chrome；只有用户明确要求时才能执行 `stop`。
