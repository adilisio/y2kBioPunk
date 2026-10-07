# shot.ps1 — launch a Godot scene windowed, wait, capture screenshots, send optional keys, then kill.
# Usage: powershell -File ops/tools/shot.ps1 -Scene res://scenes/FloodedMall_Greybox.tscn -Out ops/runs/shots/greybox -WaitSec 8 -Keys "k","w","w"
param(
    [string]$Scene = "",
    [string]$Out = "ops/runs/shots/shot",
    [int]$WaitSec = 8,
    [string[]]$Keys = @(),
    [int]$KeyHoldMs = 400,
    [int]$Width = 1280,
    [int]$Height = 720
)
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))
Set-Location $root
$godot = Join-Path $root "Godot_v4.3-stable_win64.exe"
$outDir = Split-Path -Parent $Out
if ($outDir -and -not (Test-Path $outDir)) { New-Item -ItemType Directory -Force $outDir | Out-Null }

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$args = @("--path", $root, "--windowed", "--resolution", "${Width}x${Height}", "--position", "100,100")
if ($Scene -ne "") { $args += $Scene }
$log = "$Out.log"
$p = Start-Process -FilePath $godot -ArgumentList $args -PassThru -RedirectStandardOutput $log -RedirectStandardError "$Out.err.log"
Start-Sleep -Seconds $WaitSec

function Capture([string]$path) {
    $bounds = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
    $bmp = New-Object System.Drawing.Bitmap $bounds.Width, $bounds.Height
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.CopyFromScreen($bounds.Location, [System.Drawing.Point]::Empty, $bounds.Size)
    $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose(); $bmp.Dispose()
}

# Bring window to front
$sig = '[DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);'
$u32 = Add-Type -MemberDefinition $sig -Name U32 -Namespace W -PassThru
Start-Sleep -Milliseconds 300
$p.Refresh()
if ($p.MainWindowHandle -ne 0) { $u32::SetForegroundWindow($p.MainWindowHandle) | Out-Null }
Start-Sleep -Milliseconds 300

Capture "$Out.0.png"
$i = 1
foreach ($k in $Keys) {
    [System.Windows.Forms.SendKeys]::SendWait($k)
    Start-Sleep -Milliseconds $KeyHoldMs
    Capture "$Out.$i.png"
    $i++
}
Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue
Write-Output "captured $i frames to $Out.*.png ; log: $log"
