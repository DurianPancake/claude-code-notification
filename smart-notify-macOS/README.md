# smart-notify-macOS — Claude Code macOS 通知 Hook 教程（参考 Windows 版）

用于 Claude Code CLI 的 macOS 通知 hooks 脚本，在以下场景发送提醒（声音 + 尽力发送系统通知）：

- **需要用户交互/授权**：`PermissionRequest` + `Notification(permission_prompt)`
- **任务完成**：`Stop`



同时具备 **智能通知**：仅在终端/IDE 窗口非活动（不在前台）时提醒；测试/强制提醒可加 `-Force` 跳过检测。

> macOS 特性：专注模式/勿扰可能会抑制通知横幅/声音。为了“至少响一声”，本方案使用 `afplay` 播放系统音效作为兜底；通知用 `osascript` 尽力发送（可能被拦截属于正常现象）。

---

## 目录结构

推荐放到仓库目录并用软链接映射到 `~/.claude/hooks`，便于同步更新：

```
smart-notify-macOS/
└── notify.sh   # PermissionRequest / Notification / Stop 通用脚本
```
---

## 事件对照（参考 Windows 版）

| 场景      | Hook              | matcher           | 通知标题                              | 声音     | 说明                                            |
| ------- | ----------------- | ----------------- | --------------------------------- | ------ | --------------------------------------------- |
| 需要授权/交互 | PermissionRequest | -                 | Claude Code - Permission Required | Funk   | Claude 需要你批准执行命令                              |
| 需要授权/交互 | Notification      | permission_prompt | Claude Code - Permission Required | Funk   | 兼容 Claude 用 Notification 触发 permission_prompt |
| 任务完成    | Stop              | -                 | Claude Code - Task Completed      | Bottle | 任务完成                                          |

---

## macOS 必要依赖

### 必要依赖（系统自带/常见）

- `bash`
- `python3`（用于解析 hook JSON）
- `osascript`（尝试发送系统通知）
- `afplay`（播放系统提示音，Focus/勿扰下依然通常可听到）



> brew install python3 

---

## 必要步骤

### 1）确保脚本 `notify.sh`

保存为：`~/.claude/hooks/smart-notify-macOS/notify.sh`（或你的仓库目录，后续再软链接进去）。

见本工程文件

赋予可执行权限：

```bash
chmod +x ~/.claude/hooks/smart-notify-macOS/notify.sh
```

---

### 2）将脚本放入 Claude hooks 目录（推荐软链接）

建议用软链接：

```
mkdir -p ~/.claude/hooks

# 软链接（将你的仓库 hooks 目录映射到 Claude 的 hooks 目录）
# 将 <SOURCE_DIR> 替换为你的实际目录（smart-notify-macOS 所在目录）
ln -sfn "<SOURCE_DIR>/smart-notify-macOS" "$HOME/.claude/hooks/smart-notify-macOS"

# 示例：
# ln -sfn "/Users/<USER>/path/to/repo/claude/hooks/smart-notify-macOS" "$HOME/.claude/hooks/smart-notify-macOS"
```

验证：

```bash
ls -la ~/.claude/hooks/smart-notify-macOS
```

---

### 3）配置 `~/.claude/settings.json`（三种 hook）

将以下内容合并到你的 `~/.claude/settings.json` 的 `"hooks"` 中：

```json
{
  "hooks": {
    "PermissionRequest": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/.claude/hooks/smart-notify-macOS/notify.sh",
            "timeout": 10
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
            "command": "bash ~/.claude/hooks/smart-notify-macOS/notify.sh",
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
            "command": "bash ~/.claude/hooks/smart-notify-macOS/notify.sh",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
```
**建议使用CC 配置**

重启 Claude Code CLI 后，在 Claude Code 内运行：

- `/hooks` 检查 hooks 是否注册成功

---

## 本地模拟测试（不依赖 Claude）

为避免“智能通知（前台是终端/IDE）”导致不提醒，测试时统一加 `-Force`：

```bash
# 1) 模拟 PermissionRequest（需要你批准执行命令）
echo '{"hook_event_name":"PermissionRequest","message":"Claude 需要权限执行命令"}' \
  | bash ~/.claude/hooks/smart-notify-macOS/notify.sh -Force

# 2) 模拟 Notification(permission_prompt)
echo '{"hook_event_name":"Notification","matcher":"permission_prompt","message":"Claude 需要权限运行命令"}' \
  | bash ~/.claude/hooks/smart-notify-macOS/notify.sh -Force

# 3) 模拟 Stop（任务完成）
echo '{"hook_event_name":"Stop","message":"任务已完成"}' \
  | bash ~/.claude/hooks/smart-notify-macOS/notify.sh -Force
```

---

## 自定义声音（macOS）

系统自带音效列表：

```bash
ls /System/Library/Sounds
```

你可以在脚本里替换这两行：

- 交互/授权：`/System/Library/Sounds/Funk.aiff`
- 完成提示：`/System/Library/Sounds/Bottle.aiff`

```
# 本工程另外提供了声音测试文件
cat ~/.claude/hooks/smart-notify-macOS/test_sound.sh
```

---

## macOS 排错指南（常见问题）

---

### 1）专注模式/勿扰开启时通知不显示、或不响

这是 macOS 的系统行为：Focus 可能抑制通知（即便你允许了某个 App 的通知，仍可能过滤横幅/声音）。

本方案设计为：

- **声音用 `afplay`**：Focus 下通常也能发出声音
- **通知用 `osascript` 尽力发送**：可能被系统抑制属于正常现象

验证系统音频是否正常：

```bash
afplay /System/Library/Sounds/Glass.aiff
```

---

### 2）通知完全不出现（即使关掉专注模式）

检查：

- 系统设置 → 通知 → iTerm / Terminal：允许通知、横幅/提醒样式
- 可尝试重启通知服务：

```bash
killall NotificationCenter || true
killall usernoted || true
```

---

### 3）JSONDecodeError / hook_event_name 为空

说明 stdin 不是 JSON 或为空。确保：

- 通过 Claude Code hook 触发（会传 JSON stdin）
- 手动测试时用 `echo '{...}' | bash ...` 形式

---

### 4）“我在终端里测试不提醒”

因为脚本有“智能通知”逻辑：前台是终端/IDE 时默认不提醒。
测试请加 `-Force`：

```bash
... | bash notify.sh -Force
```

---

## 验证配置

在 Claude Code 中运行：

- `/hooks` 查看已注册 hooks

---

## 参考

- Claude Code Hooks 文档：https://code.claude.com/docs/zh-CN/hooks-guide