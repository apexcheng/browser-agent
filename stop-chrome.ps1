$ErrorActionPreference = "Stop"
. "$PSScriptRoot\config.windows.ps1"

function Test-CdpReady {
    try {
        Invoke-RestMethod -Uri "$CdpUrl/json/version" -TimeoutSec 2 | Out-Null
        return $true
    } catch {
        return $false
    }
}

$profile = $ChromeProfileDir.ToLowerInvariant()
$processes = @(
    Get-CimInstance Win32_Process -Filter "Name='chrome.exe'" -ErrorAction SilentlyContinue |
        Where-Object {
            $_.CommandLine -and
            $_.CommandLine.ToLowerInvariant().Contains("--user-data-dir") -and
            $_.CommandLine.ToLowerInvariant().Contains($profile)
        }
)

if ($processes.Count -eq 0) {
    Write-Output "Chrome AI Profile 未运行"
    exit 0
}

$processes | ForEach-Object { Stop-Process -Id $_.ProcessId -ErrorAction SilentlyContinue }

for ($i = 0; $i -lt 25; $i++) {
    if (-not (Test-CdpReady)) {
        Remove-Item -Force -ErrorAction SilentlyContinue (Join-Path $BrowserAgentHome "run\chrome.pid")
        Write-Output "Chrome AI Profile 已停止"
        exit 0
    }
    Start-Sleep -Milliseconds 200
}

Write-Error "Chrome 未在预期时间内停止，请手动关闭该窗口"
exit 1
