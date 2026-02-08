# smart-notify-windows - Windows 通知 Hook

用于 Claude Code 的 Windows 通知 hooks 脚本，在以下场景发送系统通知：

| 事件           | 匹配器               | 通知标题                              | 说明       |
|--------------|-------------------|-----------------------------------|----------|
| Notification | permission_prompt | Claude Code - Permission Required | 需要批准执行命令 |
| Stop         | -                 | Claude Code - Task Completed      | 任务完成     |

**智能通知**：仅在终端/IDE 窗口非活动时发送通知。

### 文件说明

```
smart-notify-windows/
└── hwnd.ps1     # SessionStart Hook，获取并保存终端窗口句柄到：$TEMP/claude_terminal_$session_id.txt
└── notify.ps1   # Notification Hook，智能判断是否发送通知
```

1. 复制文件

TIPS：可以通过windows的目录链接能力快速引用并自动同步。

```
cmd /c mklink /j "%USERPROFILE%\.claude\hooks" "D:\workspace\ai-toolkit\claude\hooks"
```

```
mklink命令说明：
- /j：创建目录联接（目录符号链接）
- 删除链接本身时，不会删除源目录，删除链接中的内容会删除源目录中的内容
- 移动原文件夹会导致链接失效
- 仅限本地盘符，不支持网络路径/移动设备
- 不要把一个文件夹链接到它自己的子文件夹里，防止递归循环风险
- 分辨：在 CMD 输入 dir 查看，带有 <JUNCTION> 字样的就是目录符号链接
```

2. 添加配置项

将配置添加到用户设置文件 `~/.claude/settings.json`，推荐使用 CC-Switch 进行配置管理，然后重启claude code cli观察效果

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "command": "powershell -ExecutionPolicy Bypass -NoProfile -File \"%USERPROFILE%/.claude/hooks/smart-notify-windows/hwnd.ps1\"",
            "timeout": 10,
            "type": "command"
          }
        ]
      }
    ],
    "Notification": [
      {
        "matcher": "permission_prompt",
        "hooks": [
          {
            "type": "command",
            "command": "powershell -ExecutionPolicy Bypass -NoProfile -File \"%USERPROFILE%/.claude/hooks/smart-notify-windows/notify.ps1\"",
            "timeout": 10
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "powershell -ExecutionPolicy Bypass -NoProfile -File \"%USERPROFILE%/.claude/hooks/smart-notify-windows/notify.ps1\"",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
```

#### 测试脚本

可以直接运行 PowerShell 脚本进行测试（使用 `-Force` 跳过活动窗口检测）：

```powershell
# 模拟权限请求通知
echo '{"hook_event_name":"Notification","message":"Claude需要权限运行命令"}' | powershell -ExecutionPolicy Bypass -File ".\claude\hooks\smart-notify-windows\notify.ps1" -Force

# 模拟任务完成通知
echo '{"hook_event_name":"Stop"}' | powershell -ExecutionPolicy Bypass -File ".\claude\hooks\smart-notify-windows\notify.ps1" -Force
```

#### 故障排除

1. 检查 Windows 通知设置是否开启
2. 确保 PowerShell 执行策略允许运行脚本

## 验证配置

在 Claude Code 中运行 `/hooks` 命令查看已注册的 hooks。

## 参考

- [Claude Code Hooks 文档](https://code.claude.com/docs/zh-CN/hooks-guide)
