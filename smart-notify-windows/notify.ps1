# Notification Hook - 智能判断是否发送通知
param(
    [switch]$Force
)

# 读取 hook 输入
$input_json = $input | ConvertFrom-Json
$message = $input_json.message
$notification_type = $input_json.notification_type
$session_id = $input_json.session_id
$hook_event_name = $input_json.hook_event_name

# Set default message if not provided
if (-not $message)
{
    switch ($hook_event_name)
    {
        "Stop" {
            $message = [char]0x4EFB + [char]0x52A1 + [char]0x5DF2 + [char]0x5B8C + [char]0x6210
        }
        default {
            $message = "Claude Code " + [char]0x901A + [char]0x77E5
        }
    }
}

# 判断是否需要发送通知（除非使用 -Force 参数）
if (-not $Force)
{
    $tempFile = "$env:TEMP\claude_terminal_$session_id.txt"

    if (Test-Path $tempFile)
    {
        $savedHwnd = (Get-Content $tempFile -Raw).Trim()

        Add-Type @"
using System;
using System.Runtime.InteropServices;
public class WinAPI {
    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();
}
"@

        $currentHwnd = [WinAPI]::GetForegroundWindow().ToInt64()

        if ($currentHwnd -eq $savedHwnd)
        {
            exit 0
        }
    }
}

# 发送 Windows 通知
Add-Type -AssemblyName System.Windows.Forms
$notify = New-Object System.Windows.Forms.NotifyIcon
$notify.Icon = [System.Drawing.SystemIcons]::Information
$notify.Visible = $true
$notify.ShowBalloonTip(3000, "Claude Code", $message, [System.Windows.Forms.ToolTipIcon]::Info)
Start-Sleep -Seconds 4
$notify.Dispose()

exit 0
