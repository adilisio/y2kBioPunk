# Inspect real PCK directories and run templates from their own output directories.
[CmdletBinding()]
param([int]$TimeoutSeconds = 180)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$Runs = Join-Path $RepoRoot ('ops\runs\export\smoke_' + (Get-Date -Format 'yyyyMMdd_HHmmss'))
$FailurePattern = '(?im)\bERROR\b|Cannot open file|Failed loading resource|Resource file not found|(?:GDExtension|dynamic library).*(?:fail|not found|cannot|could not)'
# The headless suite's established gate is exit/script/assertion status. The dummy renderer
# emits a known null-mesh ERROR even on passing tests; retain it in the complete captured output.
# Resource and extension failures still fail QA. The rendered release rejects EVERY ERROR line.
$TestFailurePattern = '(?im)SCRIPT ERROR:|Cannot open file|Failed loading resource|Resource file not found|(?:GDExtension|dynamic library).*(?:fail|not found|cannot|could not)'
$ScriptRefusalPattern = '(?im)(unknown|unrecognized|invalid|unsupported).*(?:-s|script)|(?:-s|script).*(?:not supported|not available|not allowed|only.*editor)'

function Read-Pack([string]$Path) {
    $stream = [IO.File]::OpenRead($Path)
    $reader = [IO.BinaryReader]::new($stream)
    try {
        if ($reader.ReadUInt32() -ne 0x43504447) { throw "Invalid PCK magic: $Path" }
        if ($reader.ReadUInt32() -ne 2) { throw "Unsupported PCK version: $Path" }
        $major = $reader.ReadUInt32(); $minor = $reader.ReadUInt32(); $patch = $reader.ReadUInt32()
        $flags = $reader.ReadUInt32(); $base = $reader.ReadUInt64()
        if (($flags -band 1) -ne 0) { throw "Encrypted PCK directory: $Path" }
        $null = $reader.ReadBytes(64)
        $count = $reader.ReadUInt32()
        Write-Host "PCK: $Path (Godot $major.$minor.$patch, $count entries)"
        $entries = @{}
        for ($i = 0; $i -lt $count; $i++) {
            $length = $reader.ReadUInt32()
            if ($length -gt 1048576) { throw 'Invalid PCK path length.' }
            $name = [Text.Encoding]::UTF8.GetString($reader.ReadBytes($length)).TrimEnd([char]0)
            $offset = $base + $reader.ReadUInt64(); $size = $reader.ReadUInt64()
            $null = $reader.ReadBytes(16); $fileFlags = $reader.ReadUInt32()
            if ($offset + $size -gt $stream.Length -or $fileFlags -ne 0) { throw "Invalid/encrypted entry: $name" }
            if ($entries.ContainsKey($name)) { throw "Duplicate PCK entry: $name" }
            $entries[$name] = [PSCustomObject]@{ Size = $size; Offset = $offset }
        }
        return $entries
    } finally { $reader.Dispose(); $stream.Dispose() }
}

function Read-PackText([string]$Path, $Entry) {
    if ($Entry.Size -gt 1048576) { throw 'Oversized PCK import/remap metadata.' }
    $stream = [IO.File]::OpenRead($Path)
    $reader = [IO.BinaryReader]::new($stream)
    try {
        $stream.Position = $Entry.Offset
        return [Text.Encoding]::UTF8.GetString($reader.ReadBytes($Entry.Size))
    } finally { $reader.Dispose(); $stream.Dispose() }
}

function Assert-Pack($Entries, [bool]$QA, [string]$PackPath) {
    $required = @('intro_video.ogv', 'icon.svg', 'Skate_Grind.res', 'biopunk.gdextension')
    $music = @(Get-ChildItem -LiteralPath (Join-Path $RepoRoot 'music') -Filter '*.mp3' -File)
    $models = @(Get-ChildItem -LiteralPath (Join-Path $RepoRoot 'assets\models') -Filter '*.glb' -File)
    if ($music.Count -ne 8 -or $models.Count -ne 7) { throw "Expected 8 tracks and 7 models; found $($music.Count) and $($models.Count)." }
    $required += @($music | ForEach-Object { 'music/' + $_.Name })
    $required += @($models | ForEach-Object { 'assets/models/' + $_.Name })
    $required += 'bin/libbiopunk.windows.template_release.x86_64.dll'
    if ($QA) {
        $required += 'bin/libbiopunk.windows.template_debug.x86_64.dll'
        $required += 'ops/tools/shot_harness.gd'
        $required += @(Get-ChildItem -LiteralPath (Join-Path $RepoRoot 'tests') -Filter '*.gd' -File | ForEach-Object { 'tests/' + $_.Name })
    }
    foreach ($relative in $required) {
        # Godot exports imported resources as .import metadata plus platform-ready payloads.
        # Prove both the logical source path AND every referenced payload inside this actual PCK.
        $key = 'res://' + $relative
        if ($Entries.ContainsKey($key)) {
            if ($Entries[$key].Size -eq 0) { throw "Empty resource: $key" }
            Write-Host "PACKED: $key (direct, $($Entries[$key].Size) bytes)"
        } else {
            $metadata = if ($Entries.ContainsKey($key + '.import')) { $key + '.import' } else { $key + '.remap' }
            if (-not $Entries.ContainsKey($metadata)) { throw "PCK missing $key" }
            $text = Read-PackText $PackPath $Entries[$metadata]
            $targets = [regex]::Matches($text, '(?m)^path(?:\.[^=]+)?="(res://[^"]+)"')
            if ($targets.Count -eq 0) { throw "No payload remap in $metadata" }
            foreach ($match in $targets) {
                $target = $match.Groups[1].Value
                if (-not $Entries.ContainsKey($target) -or $Entries[$target].Size -eq 0) { throw "Missing/empty import payload: $target" }
                Write-Host "PACKED: $key -> $target ($($Entries[$target].Size) bytes; via $metadata)"
            }
        }
    }
    foreach ($key in $Entries.Keys) {
        $relative = $key -replace '^res://', ''
        if ($relative -match '^(godot-cpp|src|\.worktrees|build)/|^bin/~|^bin/.*\.(pdb|lib|exp|ilk|tmp)$' -or $relative -match '\.(md|log)$' -or
            $relative -in @('Prompt___Generate_a_aspect.mp4', 'test_proc_mat.tres', 'test_quad.tres', 'SConstruct', '.sconsign.dblite', '.gitmodules', 'export_presets.cfg')) {
            throw "Forbidden PCK entry: $key"
        }
        if ($relative -like 'ops/*' -and (-not $QA -or $relative -ne 'ops/tools/shot_harness.gd')) { throw "Forbidden ops entry: $key" }
        if (-not $QA -and $relative -like 'tests/*') { throw "Release contains tests: $key" }
    }
    Write-Host "FILTERS: PASS (QA=$QA; no forbidden source/ops/test/build files)"
}

function Invoke-Packaged([string]$Exe, [string[]]$Arguments, [string]$Label) {
    Write-Host ('COMMAND: ' + $Exe + ' ' + ($Arguments -join ' '))
    $out = Join-Path $Runs ($Label + '.stdout.log'); $err = Join-Path $Runs ($Label + '.stderr.log')
    $proc = Start-Process -FilePath $Exe -ArgumentList $Arguments -WorkingDirectory (Split-Path -Parent $Exe) `
        -WindowStyle Hidden -RedirectStandardOutput $out -RedirectStandardError $err -PassThru
    $null = $proc.Handle
    if (-not $proc.WaitForExit($TimeoutSeconds * 1000)) {
        & taskkill.exe /PID $proc.Id /T /F | Out-Host
        throw "$Label timed out after ${TimeoutSeconds}s (terminated only its process tree)."
    }
    $output = [IO.File]::ReadAllText($out) + [IO.File]::ReadAllText($err)
    Write-Host $output
    Write-Host "EXIT: $($proc.ExitCode) ($Label)"
    return [PSCustomObject]@{ ExitCode = $proc.ExitCode; Output = $output }
}

try {
    New-Item -ItemType Directory -Path $Runs -Force | Out-Null
    Write-Host "Worktree: $RepoRoot"
    Write-Host "Logs: $Runs"
    $releaseDir = Join-Path $RepoRoot 'build\release'; $qaDir = Join-Path $RepoRoot 'build\qa'
    $release = Read-Pack (Join-Path $releaseDir 'Y2K-BioPunk.pck')
    Write-Host 'RELEASE PCK DIRECTORY (bytes, resource path):'
    foreach ($key in ($release.Keys | Sort-Object)) { Write-Host ('{0}  {1}' -f $release[$key].Size, $key) }
    Assert-Pack $release $false (Join-Path $releaseDir 'Y2K-BioPunk.pck')
    $qa = Read-Pack (Join-Path $qaDir 'Y2K-BioPunk-QA.pck')
    Assert-Pack $qa $true (Join-Path $qaDir 'Y2K-BioPunk-QA.pck')
    $failedTests = @()
    foreach ($test in @('test_slice_e2e', 'test_menu_flow')) {
        $result = Invoke-Packaged (Join-Path $qaDir 'Y2K-BioPunk-QA.console.exe') @('--headless', '-s', "res://tests/$test.gd") $test
        if ($result.Output -match $ScriptRefusalPattern) {
            Write-Host 'Short script option refused; retrying --script.'
            $result = Invoke-Packaged (Join-Path $qaDir 'Y2K-BioPunk-QA.console.exe') @('--headless', '--script', "res://tests/$test.gd") ($test + '_long')
            if ($result.Output -match $ScriptRefusalPattern) { throw "STOP: Exported template refused both -s and --script; see exact output above and $Runs." }
        }
        if ($result.ExitCode -ne 0 -or $result.Output -match $TestFailurePattern -or $result.Output -match 'RESULT: FAIL' -or $result.Output -notmatch 'RESULT: PASS') {
            $failedTests += $test
            Write-Host "PACKAGED TEST: FAIL ($test); continuing the other independent smoke checks."
        } else {
            Write-Host "PACKAGED TEST: PASS ($test)"
        }
    }
    $result = Invoke-Packaged (Join-Path $releaseDir 'Y2K-BioPunk.console.exe') @('--windowed', '--resolution', '1280x720', '--position', '2000,2000', '--quit-after', '600') 'release_launch'
    if ($result.ExitCode -ne 0 -or $result.Output -match $FailurePattern) { throw 'Release launch failed; see exact output above.' }
    Write-Host 'RELEASE LAUNCH: PASS (600 frames, off-screen; no matching error lines)'
    if ($failedTests.Count -gt 0) { throw "Packaged tests failed: $($failedTests -join ', '); see exact output above and $Runs." }
    Write-Host 'SMOKE: PASS'
    exit 0
} catch {
    Write-Host "SMOKE: FAIL - $($_.Exception.Message)"
    exit 1
}
