# Push build/release to the itch.io page's Windows channel with butler (run after build_release.ps1 and smoke_packaged.ps1).
# One-time setup: install butler (https://itch.io/docs/butler/installing.html) and run `butler login`.
[CmdletBinding()]
param(
    [string]$Target = 'signallampgames/y2k-bio-punk',
    [string]$Channel = 'windows',
    [string]$Butler = '',
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$Release = Join-Path $RepoRoot 'build\release'

try {
    if ($Butler -eq '') {
        $onPath = Get-Command butler.exe -ErrorAction SilentlyContinue
        $Butler = if ($onPath) { $onPath.Source } else { Join-Path $env:LOCALAPPDATA 'Programs\butler\butler.exe' }
    }
    if (-not (Test-Path -LiteralPath $Butler)) { throw "butler not found at $Butler; install it or pass -Butler <path>." }
    foreach ($name in @('Y2K-BioPunk.exe', 'Y2K-BioPunk.pck', 'libbiopunk.windows.template_release.x86_64.dll', 'BUILD-INFO.txt')) {
        if (-not (Test-Path -LiteralPath (Join-Path $Release $name))) { throw "build/release is missing $name; run build_release.ps1 first." }
    }
    # Version shown on itch: the commit the build came from, read from BUILD-INFO rather than the current checkout.
    $info = [IO.File]::ReadAllText((Join-Path $Release 'BUILD-INFO.txt'))
    if ($info -notmatch '(?m)^Git: ([0-9a-f]{7,40})') { throw 'BUILD-INFO.txt has no Git line.' }
    $userVersion = 'VS1.1-' + $Matches[1].Substring(0, 7)
    if ($info -match '(?m)^Working tree modified: True') {
        Write-Host 'WARNING: BUILD-INFO says the working tree was modified when this build was made.'
    }
    $pushArgs = @('push', $Release, "${Target}:${Channel}", '--userversion', $userVersion)
    if ($DryRun) { $pushArgs += '--dry-run' }
    Write-Host ('COMMAND: ' + $Butler + ' ' + ($pushArgs -join ' '))
    & $Butler @pushArgs
    if ($LASTEXITCODE -ne 0) { throw "butler push exited $LASTEXITCODE (not logged in? run: `"$Butler`" login)" }
    Write-Host "PUSH: PASS ($userVersion -> ${Target}:${Channel}$(if ($DryRun) { ', dry run' }))"
    exit 0
} catch {
    Write-Host "PUSH: FAIL - $($_.Exception.Message)"
    exit 1
}
