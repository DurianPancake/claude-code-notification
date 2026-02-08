# SessionStart Hook - 保存终端窗口 HWND
$input_json = $input | ConvertFrom-Json
$session_id = $input_json.session_id

# 获取前台窗口
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class WinAPI {
    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();
}
"@

$hwnd = [WinAPI]::GetForegroundWindow().ToInt64()

# 保存到临时文件（使用 session_id 避免冲突）
$tempFile = "$env:TEMP\claude_terminal_$session_id.txt"
$hwnd | Out-File -FilePath $tempFile -Encoding utf8

exit 0
