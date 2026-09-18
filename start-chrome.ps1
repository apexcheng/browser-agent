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

function Get-ProfileChromeProcesses {
    $profile = $ChromeProfileDir.ToLowerInvariant()
    Get-CimInstance Win32_Process -Filter "Name='chrome.exe'" -ErrorAction SilentlyContinue |
        Where-Object {
            $_.CommandLine -and
            $_.CommandLine.ToLowerInvariant().Contains("--user-data-dir") -and
            $_.CommandLine.ToLowerInvariant().Contains($profile)
        }
}

New-Item -ItemType Directory -Force -Path $ChromeProfileDir, (Join-Path $BrowserAgentHome "logs"), (Join-Path $BrowserAgentHome "run") | Out-Null

if (-not $ChromeBin -or -not (Test-Path $ChromeBin)) {
    Write-Error "Chrome 不存在: $ChromeBin"
    exit 1
}

if (Test-CdpReady) {
    if (Get-ProfileChromeProcesses) {
        Write-Output "Chrome AI Profile 已运行"
        Write-Output "CDP: $CdpUrl"
        exit 0
    }
    Write-Error "端口 $CdpPort 已被其他 Chrome 或程序占用"
    exit 1
}

if (Get-ProfileChromeProcesses) {
    Write-Error "Chrome AI Profile 已被占用，但 CDP 端口不可用。请先关闭该 Profile 的 Chrome。"
    exit 1
}

$arguments = @(
    "--remote-debugging-address=$CdpHost",
    "--remote-debugging-port=$CdpPort",
    "--user-data-dir=`"$ChromeProfileDir`"",
    "--profile-directory=Default",
    "--restore-last-session",
    "--no-first-run",
    "--no-default-browser-check"
)

Start-Process -FilePath $ChromeBin -ArgumentList $arguments | Out-Null

for ($i = 0; $i -lt 50; $i++) {
    if (Test-CdpReady) {
        Write-Output "Chrome AI Profile 已启动"
        Write-Output "Profile: $ChromeProfileDir"
        Write-Output "CDP: $CdpUrl"
        exit 0
    }
    Start-Sleep -Milliseconds 200
}

Write-Error "Chrome 启动失败，CDP 未在预期时间内就绪"
exit 1
