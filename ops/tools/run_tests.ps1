# ops/tools/run_tests.ps1
# One-command headless test suite runner for Y2K Bio-Punk ARPG.
# Runs every tests/test_*.gd and tests/verify_*.gd with 120s timeout,
# captures exit codes, checks for SCRIPT ERROR / RESULT: FAIL,
# outputs a formatted summary table, writes a persistent log, and exits non-zero on failure.

[CmdletBinding()]
param(
    [string]$GodotBin = "",
    [int]$TimeoutSeconds = 120
)

$ErrorActionPreference = "Stop"

# 1. Resolve repository root and engine binary
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = (Resolve-Path (Join-Path $ScriptDir "..\..")).Path

if ([string]::IsNullOrWhiteSpace($GodotBin)) {
    $Candidates = @(
        (Join-Path $RepoRoot "Godot_v4.3-stable_win64.exe"),
        (Join-Path $RepoRoot "..\..\Godot_v4.3-stable_win64.exe"),
        "Godot_v4.3-stable_win64.exe"
    )
    foreach ($c in $Candidates) {
        if (Test-Path $c) {
            $GodotBin = (Resolve-Path $c).Path
            break
        }
    }
}

if (-not (Test-Path $GodotBin)) {
    Write-Error "Godot engine binary not found. Checked: $GodotBin"
    exit 1
}

Write-Host "================================================================="
Write-Host " Y2K BIO-PUNK ARPG - TEST SUITE RUNNER"
Write-Host " Engine : $GodotBin"
Write-Host " Worktree: $RepoRoot"
Write-Host " Timeout: ${TimeoutSeconds}s per test"
Write-Host "================================================================="

# 2. Discover test scripts (test_*.gd and verify_*.gd, excluding _* helpers)
$TestsDir = Join-Path $RepoRoot "tests"
if (-not (Test-Path $TestsDir)) {
    Write-Error "Tests directory not found: $TestsDir"
    exit 1
}

$TestFiles = Get-ChildItem -Path $TestsDir -File | Where-Object {
    ($_.Name -like "test_*.gd" -or $_.Name -like "verify_*.gd") -and
    -not ($_.Name -like "_*.gd")
} | Sort-Object Name

if ($TestFiles.Count -eq 0) {
    Write-Warning "No test scripts found matching test_*.gd or verify_*.gd in $TestsDir"
    exit 0
}

Write-Host "Discovered $($TestFiles.Count) test suite files."

# 3. Setup run log file in ops/runs/tests/<timestamp>.log
$RunsDir = Join-Path $RepoRoot "ops\runs\tests"
if (-not (Test-Path $RunsDir)) {
    New-Item -ItemType Directory -Path $RunsDir -Force | Out-Null
}

$Timestamp = (Get-Date).ToString("yyyyMMdd_HHmmss")
$LogFilePath = Join-Path $RunsDir "$Timestamp.log"
$LogBuffer = [System.Text.StringBuilder]::new()

[void]$LogBuffer.AppendLine("=================================================================")
[void]$LogBuffer.AppendLine("TEST RUN LOG: $Timestamp")
[void]$LogBuffer.AppendLine("Engine: $GodotBin")
[void]$LogBuffer.AppendLine("Worktree: $RepoRoot")
[void]$LogBuffer.AppendLine("Total Tests: $($TestFiles.Count)")
[void]$LogBuffer.AppendLine("=================================================================`n")

# 4. Execute test suite
$Results = [System.Collections.Generic.List[PSCustomObject]]::new()
$TotalFailed = 0

foreach ($testFile in $TestFiles) {
    $TestRelPath = "tests/$($testFile.Name)"
    $TestFullName = $testFile.FullName
    $TempLog = Join-Path ([System.IO.Path]::GetTempPath()) ("godot_test_" + [System.Guid]::NewGuid().ToString() + ".log")

    [void]$LogBuffer.AppendLine("--- START: $TestRelPath ---")

    $Sw = [System.Diagnostics.Stopwatch]::StartNew()
    $TimedOut = $false
    $ExitCode = -1

    # Launch headless Godot directly (no cmd.exe wrapper) so the exit code is Godot's own and
    # a timeout kills only THIS process, never other agents' Godot instances in other worktrees.
    $TempErr = "$TempLog.err"
    $Proc = Start-Process -FilePath $GodotBin -ArgumentList @("--headless", "--path", "`"$RepoRoot`"", "-s", "`"$TestRelPath`"") `
        -RedirectStandardOutput $TempLog -RedirectStandardError $TempErr -PassThru -NoNewWindow
    $null = $Proc.Handle  # PowerShell 5.1 quirk: cache the handle or ExitCode reads back empty
    $Finished = $Proc.WaitForExit($TimeoutSeconds * 1000)

    $Sw.Stop()
    $DurationSec = [Math]::Round($Sw.Elapsed.TotalSeconds, 2)

    if (-not $Finished) {
        $TimedOut = $true
        try { $Proc.Kill() } catch {}
        $ExitCode = -124
    } else {
        $ExitCode = $Proc.ExitCode
    }

    # Redirected file handles can linger a moment after exit; retry the read briefly.
    $OutputContent = ""
    for ($attempt = 0; $attempt -lt 20; $attempt++) {
        try {
            $out = if (Test-Path $TempLog) { [System.IO.File]::ReadAllText($TempLog) } else { "" }
            $err = if (Test-Path $TempErr) { [System.IO.File]::ReadAllText($TempErr) } else { "" }
            $OutputContent = $out + "`n" + $err
            break
        } catch {
            Start-Sleep -Milliseconds 250
        }
    }
    Remove-Item -Path $TempLog, $TempErr -Force -ErrorAction SilentlyContinue

    [void]$LogBuffer.AppendLine($OutputContent)
    [void]$LogBuffer.AppendLine("--- END: $TestRelPath (ExitCode: $ExitCode, Time: ${DurationSec}s) ---`n")

    # Analyze result
    $HasScriptError = $OutputContent -match "SCRIPT ERROR:"
    $HasResultFail = $OutputContent -match "RESULT: FAIL"
    $HasSkip = $OutputContent -match "SKIP:"
    
    $Status = "PASS"
    $Detail = ""

    if ($TimedOut) {
        $Status = "TIMEOUT"
        $Detail = "Exceeded ${TimeoutSeconds}s limit"
        $TotalFailed++
    } elseif ($ExitCode -ne 0) {
        $Status = "FAIL"
        if ($HasScriptError) {
            $Detail = "Script error during execution (Exit $ExitCode)"
        } elseif ($HasResultFail) {
            $Detail = "Assertion checks failed (Exit $ExitCode)"
        } else {
            $Detail = "Process exited with code $ExitCode"
        }
        $TotalFailed++
    } elseif ($HasScriptError) {
        $Status = "FAIL"
        $Detail = "Unhandled SCRIPT ERROR detected"
        $TotalFailed++
    } elseif ($HasResultFail) {
        $Status = "FAIL"
        $Detail = "RESULT: FAIL detected in output"
        $TotalFailed++
    } else {
        if ($HasSkip) {
            $Status = "PASS"
            $Detail = "Passed (contains SKIP section)"
        } else {
            $Status = "PASS"
            $Detail = "All checks passed"
        }
    }

    $ResultObj = [PSCustomObject]@{
        Test     = $testFile.Name
        Status   = $Status
        ExitCode = $ExitCode
        Time     = "${DurationSec}s"
        Details  = $Detail
    }
    $Results.Add($ResultObj)

    # Console feedback per test
    $Color = if ($Status -eq "PASS") { "Green" } elseif ($Status -eq "TIMEOUT") { "Yellow" } else { "Red" }
    Write-Host ("[{0}] {1,-32} (Code: {2,2}, Time: {3,6}) - {4}" -f $Status, $testFile.Name, $ExitCode, "${DurationSec}s", $Detail) -ForegroundColor $Color
}

# 5. Output summary table
Write-Host "`n================================================================="
Write-Host " TEST RUN SUMMARY"
Write-Host "================================================================="
$Results | Format-Table -Property Test, Status, ExitCode, Time, Details -AutoSize | Out-String | Write-Host

$PassedCount = ($Results | Where-Object { $_.Status -eq "PASS" }).Count
$FailedCount = ($Results | Where-Object { $_.Status -ne "PASS" }).Count

Write-Host "Totals: $($Results.Count) tests | $PassedCount PASSED | $FailedCount FAILED"
Write-Host "Full log saved to: $LogFilePath"

[void]$LogBuffer.AppendLine("=================================================================")
[void]$LogBuffer.AppendLine("SUMMARY: $($Results.Count) Total | $PassedCount PASSED | $FailedCount FAILED")
[void]$LogBuffer.AppendLine("=================================================================")
[System.IO.File]::WriteAllText($LogFilePath, $LogBuffer.ToString())

# 6. Exit with non-zero if any test failed
if ($TotalFailed -gt 0) {
    Write-Host "`nTest suite FAILED with $TotalFailed failure(s)." -ForegroundColor Red
    exit 1
} else {
    Write-Host "`nTest suite PASSED successfully." -ForegroundColor Green
    exit 0
}
