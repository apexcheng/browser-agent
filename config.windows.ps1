$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[Console]::OutputEncoding = $Utf8NoBom
$OutputEncoding = $Utf8NoBom

$BrowserAgentHome = if ($env:BROWSER_AGENT_HOME) {
    $env:BROWSER_AGENT_HOME
} else {
    Join-Path $HOME "browser-agent"
}

$ChromeProfileDir = if ($env:CHROME_PROFILE_DIR) {
    $env:CHROME_PROFILE_DIR
} else {
    Join-Path $BrowserAgentHome "chrome-profile"
}

$CdpHost = if ($env:CDP_HOST) { $env:CDP_HOST } else { "127.0.0.1" }
$CdpPort = if ($env:CDP_PORT) { [int]$env:CDP_PORT } else { 19312 }
$CdpUrl = "http://${CdpHost}:$CdpPort"
$BrowserAgentSession = if ($env:BROWSER_AGENT_SESSION) { $env:BROWSER_AGENT_SESSION } else { "browser-agent" }

if ($env:CHROME_BIN) {
    $ChromeBin = $env:CHROME_BIN
} else {
    $ChromeCandidates = @(
        (Join-Path $env:ProgramFiles "Google\Chrome\Application\chrome.exe"),
        (Join-Path ${env:ProgramFiles(x86)} "Google\Chrome\Application\chrome.exe"),
        (Join-Path $env:LOCALAPPDATA "Google\Chrome\Application\chrome.exe")
    )
    $ChromeBin = $ChromeCandidates | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1
}
