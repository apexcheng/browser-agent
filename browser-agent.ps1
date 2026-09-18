$ErrorActionPreference = "Stop"
. "$PSScriptRoot\config.windows.ps1"

function Show-Usage {
    @"
Usage:
  browser-agent ensure
  browser-agent start
  browser-agent status
  browser-agent connect
  browser-agent open <url>
  browser-agent snapshot
  browser-agent click <ref>
  browser-agent fill <ref> <text>
  browser-agent screenshot [ref]
  browser-agent disconnect
  browser-agent stop

All other commands are passed through to playwright-cli.
"@
}

function Require-PlaywrightCli {
    if (-not (Get-Command playwright-cli -ErrorAction SilentlyContinue)) {
        Write-Error "playwright-cli is missing. Install it with: npm install -g @playwright/cli"
        exit 1
    }
}

function Test-SessionOpen {
    & playwright-cli "-s=$BrowserAgentSession" tab-list *> $null
    return ($LASTEXITCODE -eq 0)
}

function Ensure-Chrome {
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$PSScriptRoot\ensure-chrome.ps1" | Out-Null
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

function Ensure-Attached {
    Require-PlaywrightCli
    Ensure-Chrome
    if (Test-SessionOpen) { return }

    Push-Location $BrowserAgentHome
    try {
        & playwright-cli "-s=$BrowserAgentSession" attach --cdp $CdpUrl | Out-Null
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    } finally {
        Pop-Location
    }
}

$command = if ($args.Count -gt 0) { $args[0] } else { "help" }
$rest = if ($args.Count -gt 1) { @($args[1..($args.Count - 1)]) } else { @() }

switch ($command) {
    "ensure" {
        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$PSScriptRoot\ensure-chrome.ps1"
        exit $LASTEXITCODE
    }
    "start" {
        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$PSScriptRoot\ensure-chrome.ps1"
        exit $LASTEXITCODE
    }
    "status" {
        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$PSScriptRoot\status.windows.ps1"
        exit $LASTEXITCODE
    }
    "connect" {
        Ensure-Attached
        Write-Output "Connected to Chrome AI Profile"
        Write-Output "Session: $BrowserAgentSession"
        Write-Output "CDP: $CdpUrl"
    }
    "disconnect" {
        Require-PlaywrightCli
        if (Test-SessionOpen) {
            & playwright-cli "-s=$BrowserAgentSession" detach
            exit $LASTEXITCODE
        }
        Write-Output "No Playwright CLI session is attached"
    }
    "stop" {
        Require-PlaywrightCli
        if (Test-SessionOpen) {
            & playwright-cli "-s=$BrowserAgentSession" detach *> $null
        }
        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$PSScriptRoot\stop-chrome.ps1"
        exit $LASTEXITCODE
    }
    "open" {
        if ($rest.Count -ne 1) {
            Write-Error "Usage: browser-agent open <url>"
            exit 1
        }
        Ensure-Attached
        Push-Location $BrowserAgentHome
        try {
            & playwright-cli "-s=$BrowserAgentSession" goto $rest[0]
            exit $LASTEXITCODE
        } finally {
            Pop-Location
        }
    }
    "close" {
        Write-Error "The close command is blocked for the shared Chrome. Use disconnect or stop."
        exit 1
    }
    { $_ -in @("help", "-h", "--help") } {
        Show-Usage
    }
    default {
        Ensure-Attached
        Push-Location $BrowserAgentHome
        try {
            & playwright-cli "-s=$BrowserAgentSession" $command @rest
            exit $LASTEXITCODE
        } finally {
            Pop-Location
        }
    }
}
