# setup_worktree.ps1 — create an isolated git worktree for an agent packet and make it buildable/runnable.
# Usage: powershell -ExecutionPolicy Bypass -File ops/tools/setup_worktree.ps1 -Name wp1 -Branch wp1-critical-path
param(
    [Parameter(Mandatory=$true)][string]$Name,
    [Parameter(Mandatory=$true)][string]$Branch
)
$ErrorActionPreference = "Stop"
$root = "C:\y2k-biopunk-rpg"
$wt = Join-Path $root ".worktrees\$Name"
Set-Location $root
if (-not (Test-Path (Join-Path $root ".worktrees"))) { New-Item -ItemType Directory -Force (Join-Path $root ".worktrees") | Out-Null }
if (Test-Path $wt) { Write-Output "worktree exists: $wt"; exit 0 }

git worktree add -b $Branch $wt main
if ($LASTEXITCODE -ne 0) { throw "git worktree add failed" }

# Engine binary (gitignored) and prebuilt godot-cpp lib (gitignored) so the agent can build and run headless.
Copy-Item (Join-Path $root "Godot_v4.3-stable_win64.exe") $wt
New-Item -ItemType Directory -Force (Join-Path $wt "godot-cpp\bin") | Out-Null
Copy-Item (Join-Path $root "godot-cpp\bin\*") (Join-Path $wt "godot-cpp\bin") -Recurse -Force
# godot-cpp generated sources/headers are needed by SCons; copy the generated tree if present.
if (Test-Path (Join-Path $root "godot-cpp\gen")) {
    Copy-Item (Join-Path $root "godot-cpp\gen") (Join-Path $wt "godot-cpp\gen") -Recurse -Force
}
Copy-Item (Join-Path $root "bin\*.dll") (Join-Path $wt "bin") -Force
# The submodule checkout inside the worktree is empty; populate it.
Push-Location $wt
git submodule update --init --recursive 2>&1 | Out-Null
# Re-copy the lib/gen after submodule init (init does not remove untracked files, but be safe).
Copy-Item (Join-Path $root "godot-cpp\bin\*") (Join-Path $wt "godot-cpp\bin") -Recurse -Force
if (Test-Path (Join-Path $root "godot-cpp\gen")) {
    Copy-Item (Join-Path $root "godot-cpp\gen") (Join-Path $wt "godot-cpp\gen") -Recurse -Force
}
# Import assets headless so scenes load in headless runs.
& (Join-Path $wt "Godot_v4.3-stable_win64.exe") --headless --path $wt --import 2>&1 | Select-Object -Last 3
Pop-Location
Write-Output "worktree ready: $wt (branch $Branch)"
