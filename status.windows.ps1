$ErrorActionPreference = "Stop"
. "$PSScriptRoot\config.windows.ps1"

Write-Output "Profile: $ChromeProfileDir"
Write-Output "CDP: $CdpUrl"

try {
    Invoke-RestMethod -Uri "$CdpUrl/json/version" -TimeoutSec 2 | Out-Null
} catch {
    Write-Output "Status: stopped"
    exit 1
}

Write-Output "Status: running"
$pages = @(Invoke-RestMethod -Uri "$CdpUrl/json/list" -TimeoutSec 2)
Write-Output "Pages: $($pages.Count)"
for ($i = 0; $i -lt $pages.Count; $i++) {
    $title = if ($pages[$i].title) { $pages[$i].title } else { "(no title)" }
    $url = if ($pages[$i].url) { $pages[$i].url } else { "" }
    Write-Output "  ${i}: $title — $url"
}
