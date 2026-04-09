#Requires -Version 5.1
<#
.SYNOPSIS
  Run GUT unit tests headless (requires addons/gut, see docs/RUNTIME_VERIFICATION.md).

.PARAMETER GodotExe
  Path to Godot. Default: $env:GODOT_EXE, else D:\program\Godot_v4.6.2-stable_win64.exe

.PARAMETER ProjectPath
  Project root (project.godot). Default: parent of tools/

.EXAMPLE
  .\tools\run_gut.ps1
#>
param(
	[string] $GodotExe = $env:GODOT_EXE,
	[string] $ProjectPath = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Continue"
if (-not $GodotExe -or -not (Test-Path -LiteralPath $GodotExe)) {
	$GodotExe = "D:\program\Godot_v4.6.2-stable_win64.exe"
}
if (-not (Test-Path -LiteralPath $GodotExe)) {
	Write-Error "Godot executable not found. Set -GodotExe or `$env:GODOT_EXE."
	exit 2
}
$gutScript = Join-Path $ProjectPath "addons\gut\gut_cmdln.gd"
if (-not (Test-Path -LiteralPath $gutScript)) {
	Write-Error "GUT not found at $gutScript. Install addons/gut (see docs/RUNTIME_VERIFICATION.md)."
	exit 2
}

$logFile = Join-Path $PSScriptRoot "last_gut_log.txt"
$argList = @(
	"--headless",
	"--path", $ProjectPath,
	"-s", "res://addons/gut/gut_cmdln.gd",
	"--",
	"-gdir=res://tests/unit",
	"-ginclude_subdirs",
	"-gexit"
)
Write-Host "Running GUT: $GodotExe $($argList -join ' ')"
& $GodotExe @argList 2>&1 | Tee-Object -FilePath $logFile
$code = $LASTEXITCODE
if ($null -eq $code) { $code = 0 }
Write-Host "`nExit code: $code"
Write-Host "Full log: $logFile"
exit $code
