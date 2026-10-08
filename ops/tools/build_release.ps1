# Build the standalone release and QA packages; never launches the editor or game.
[CmdletBinding()]
param([int]$TimeoutSeconds = 900)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$Engine = Join-Path $RepoRoot 'Godot_v4.3-stable_win64.exe'
$Runs = Join-Path $RepoRoot ('ops\runs\export\build_' + (Get-Date -Format 'yyyyMMdd_HHmmss'))

function Invoke-Checked([string]$File, [string[]]$Arguments, [string]$Label) {
    Write-Host ('COMMAND: ' + $File + ' ' + ($Arguments -join ' '))
    $out = Join-Path $Runs ($Label + '.stdout.log')
    $err = Join-Path $Runs ($Label + '.stderr.log')
    $proc = Start-Process -FilePath $File -ArgumentList $Arguments -WorkingDirectory $RepoRoot `
        -WindowStyle Hidden -RedirectStandardOutput $out -RedirectStandardError $err -PassThru
    $null = $proc.Handle
    if (-not $proc.WaitForExit($TimeoutSeconds * 1000)) {
        & taskkill.exe /PID $proc.Id /T /F | Out-Host
        throw "$Label timed out after ${TimeoutSeconds}s (terminated only its process tree)."
    }
    $output = [IO.File]::ReadAllText($out) + [IO.File]::ReadAllText($err)
    Write-Host $output
    Write-Host "EXIT: $($proc.ExitCode) ($Label)"
    $checkedOutput = $output
    if ($Label -in 'release', 'qa') {
        # Headless scene conversion can emit this established dummy-renderer diagnostic.
        # Keep its exact lines in the log; tolerate only this pair, never resource/script errors.
        $dummyDiagnostic = '(?m)^ERROR: Parameter "m" is null\.\r?\n\s+at: mesh_get_surface_count \(servers/rendering/dummy/storage/mesh_storage\.h:120\)\r?\n?'
        if ($output -match $dummyDiagnostic) {
            Write-Host 'WARNING: Known headless dummy-renderer null-mesh diagnostic; export exit and artifacts are checked.'
            $checkedOutput = [regex]::Replace($output, $dummyDiagnostic, '')
        }
    }
    if ($proc.ExitCode -ne 0 -or $checkedOutput -match '(?im)^\s*(SCRIPT ERROR:|ERROR:)') {
        throw "$Label failed; see $Runs"
    }
    return $output.Trim()
}

try {
    if (-not (Test-Path -LiteralPath $Engine)) { throw "Missing engine: $Engine" }
    $open = @(Get-CimInstance Win32_Process -Filter "Name = 'Godot_v4.3-stable_win64.exe'" | Where-Object {
        ($_.ExecutablePath -and [IO.Path]::GetFullPath($_.ExecutablePath) -ieq $Engine) -or
        ($_.CommandLine -and ($_.CommandLine.Replace('/', '\') -match ([regex]::Escape($RepoRoot) + '(?:["\s]|$)')))
    })
    if ($open.Count -gt 0) { throw "Godot is open from this checkout (PIDs: $($open.ProcessId -join ', ')); close it before building." }
    New-Item -ItemType Directory -Path $Runs -Force | Out-Null
    Write-Host "Worktree: $RepoRoot"
    Write-Host "Logs: $Runs"
    Push-Location $RepoRoot
    $dll = Join-Path $RepoRoot 'bin\libbiopunk.windows.template_release.x86_64.dll'
    $newest = Get-ChildItem -LiteralPath (Join-Path $RepoRoot 'src') -File | Where-Object {
        $_.Extension -in '.cpp', '.hpp'
    } | Sort-Object LastWriteTimeUtc -Descending | Select-Object -First 1
    if (-not (Test-Path -LiteralPath $dll) -or (Get-Item -LiteralPath $dll).LastWriteTimeUtc -lt $newest.LastWriteTimeUtc) {
        $null = Invoke-Checked 'py.exe' @('-3', '-m', 'SCons', 'platform=windows', 'target=template_release', '-j8') 'scons'
    } else { Write-Host 'Release DLL is current; skipping SCons.' }
    if (-not (Test-Path -LiteralPath $dll)) { throw "Build did not produce $dll" }
    $build = Join-Path $RepoRoot 'build'
    New-Item -ItemType Directory -Path $build -Force | Out-Null
    [IO.File]::WriteAllText((Join-Path $build '.gdignore'), '')
    foreach ($name in @('release', 'qa')) {
        $target = [IO.Path]::GetFullPath((Join-Path $build $name))
        # Only remove the two designated generated directories, after checking their absolute paths.
        if ($target -ine (Join-Path $RepoRoot "build\$name")) { throw "Unsafe output path: $target" }
        if (Test-Path -LiteralPath $target) { Remove-Item -LiteralPath $target -Recurse -Force }
        New-Item -ItemType Directory -Path $target | Out-Null
    }
    $null = Invoke-Checked $Engine @('--headless', '--path', "`"$RepoRoot`"", '--import') 'import'
    $null = Invoke-Checked $Engine @('--headless', '--path', "`"$RepoRoot`"", '--export-release', '"Windows Desktop"', 'build/release/Y2K-BioPunk.exe') 'release'
    $null = Invoke-Checked $Engine @('--headless', '--path', "`"$RepoRoot`"", '--export-debug', '"Windows Desktop QA"', 'build/qa/Y2K-BioPunk-QA.exe') 'qa'
    foreach ($relative in @('release/Y2K-BioPunk.exe', 'release/Y2K-BioPunk.console.exe', 'release/Y2K-BioPunk.pck',
        'release/libbiopunk.windows.template_release.x86_64.dll', 'qa/Y2K-BioPunk-QA.exe', 'qa/Y2K-BioPunk-QA.console.exe',
        'qa/Y2K-BioPunk-QA.pck', 'qa/libbiopunk.windows.template_debug.x86_64.dll')) {
        if (-not (Test-Path -LiteralPath (Join-Path $build $relative))) { throw "Export omitted $relative" }
    }
    Copy-Item -LiteralPath (Join-Path $RepoRoot 'music\CREDITS.md') -Destination (Join-Path $build 'release\MUSIC-CREDITS.txt')
    $hash = (& git.exe rev-parse HEAD | Out-String).Trim()
    if ($LASTEXITCODE -ne 0) { throw 'git rev-parse HEAD failed.' }
    $dirty = (& git.exe status --porcelain | Out-String).Trim()
    if ($LASTEXITCODE -ne 0) { throw 'git status failed.' }
    $version = Invoke-Checked $Engine @('--version') 'version'
    $info = "Git: $hash`r`nWorking tree modified: $(-not [string]::IsNullOrWhiteSpace($dirty))`r`nDate (UTC): $([DateTime]::UtcNow.ToString('o'))`r`nGodot: $version`r`nPreset: Windows Desktop (release, x86_64)`r`n"
    [IO.File]::WriteAllText((Join-Path $build 'release\BUILD-INFO.txt'), $info)
    $zip = Join-Path $build 'Y2K-BioPunk-VS1.1-win64.zip'
    Compress-Archive -Path (Join-Path $build 'release\*') -DestinationPath $zip -Force
    foreach ($name in @('release', 'qa')) {
        Write-Host "FILES: build/$name (bytes)"
        Get-ChildItem -LiteralPath (Join-Path $build $name) -File -Recurse | Sort-Object FullName | ForEach-Object {
            Write-Host ('{0}  {1}' -f $_.Length, $_.FullName.Substring($RepoRoot.Length + 1))
        }
    }
    Write-Host ('ZIP: {0} bytes  {1}' -f (Get-Item -LiteralPath $zip).Length, $zip)
    Write-Host 'BUILD: PASS'
    exit 0
} catch {
    Write-Host "BUILD: FAIL - $($_.Exception.Message)"
    exit 1
} finally {
    if ((Get-Location).Path -eq $RepoRoot) { Pop-Location -ErrorAction SilentlyContinue }
}
