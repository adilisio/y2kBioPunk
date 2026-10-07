# setup_worktree.ps1 — create an isolated git worktree for an agent packet and make it buildable/runnable.
# Usage: powershell -ExecutionPolicy Bypass -File ops/tools/setup_worktree.ps1 -Name wp1 -Branch wp1-critical-path [-From main]
param(
    [Parameter(Mandatory=$true)][string]$Name,
    [Parameter(Mandatory=$true)][string]$Branch,
    [string]$From = "main"
)
$ErrorActionPreference = "Stop"
$root = "C:\y2k-biopunk-rpg"
$wt = Join-Path $root ".worktrees\$Name"
Set-Location $root
if (-not (Test-Path (Join-Path $root ".worktrees"))) { New-Item -ItemType Directory -Force (Join-Path $root ".worktrees") | Out-Null }
if (Test-Path $wt) { Write-Output "worktree exists: $wt"; exit 0 }

git worktree add -b $Branch $wt $From
if ($LASTEXITCODE -ne 0) { throw "git worktree add failed" }

# The submodule checkout inside a worktree is empty. Copy the whole godot-cpp tree (sources, generated
# bindings, prebuilt lib) from the main checkout instead of re-initialising and recompiling it.
if (Test-Path (Join-Path $wt "godot-cpp")) { Remove-Item -Recurse -Force (Join-Path $wt "godot-cpp") }
Copy-Item (Join-Path $root "godot-cpp") (Join-Path $wt "godot-cpp") -Recurse -Force
# Engine binary (gitignored) and the current DLL.
Copy-Item (Join-Path $root "Godot_v4.3-stable_win64.exe") $wt
Copy-Item (Join-Path $root "bin\*.dll") (Join-Path $wt "bin") -Force
# Import assets headless so scenes load in headless runs. This rewrites *.import uid lines; agents must not commit those.
$ErrorActionPreference = "Continue"
& (Join-Path $wt "Godot_v4.3-stable_win64.exe") --headless --path $wt --import 2>&1 | Select-Object -Last 2
Push-Location $wt
git checkout -- "*.import" 2>$null
Pop-Location
$ErrorActionPreference = "Stop"
Write-Output "worktree ready: $wt (branch $Branch from $From)"
