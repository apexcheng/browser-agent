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

if (Test-CdpReady) {
    if (Get-ProfileChromeProcesses) {
        Write-Output "Chrome AI Profile is online"
        Write-Output "CDP: $CdpUrl"
        exit 0
    }
    Write-Error "Port $CdpPort is already in use by another Chrome instance or process"
    exit 1
}

$processes = @(Get-ProfileChromeProcesses)
if ($processes.Count -gt 0) {
    Write-Output "Chrome AI Profile process is unhealthy; restarting"
    $processes | ForEach-Object { Stop-Process -Id $_.ProcessId -ErrorAction SilentlyContinue }

    for ($i = 0; $i -lt 25; $i++) {
        if (@(Get-ProfileChromeProcesses).Count -eq 0) { break }
        Start-Sleep -Milliseconds 200
    }

    @(Get-ProfileChromeProcesses) | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
}

$listener = Get-NetTCPConnection -LocalPort $CdpPort -State Listen -ErrorAction SilentlyContinue
if ($listener) {
    Write-Error "Port $CdpPort is already in use by another process"
    exit 1
}

foreach ($name in "SingletonCookie", "SingletonLock", "SingletonSocket") {
    Remove-Item -Force -ErrorAction SilentlyContinue (Join-Path $ChromeProfileDir $name)
}

& powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$PSScriptRoot\start-chrome.ps1"
exit $LASTEXITCODE
