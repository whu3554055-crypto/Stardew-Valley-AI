#Requires -Version 5.1
<#
.SYNOPSIS
  Smoke-test the Godot project from the command line (headless).

.DESCRIPTION
  Runs the engine with --headless and --path, optionally fails if stderr contains
  SCRIPT ERROR / Failed to load script (strict mode).

.PARAMETER GodotExe
  Path to Godot executable. Default: $env:GODOT_EXE, else D:\program\Godot_v4.6.2-stable_win64.exe

.PARAMETER ProjectPath
  Path to folder containing project.godot. Default: parent of tools/

.PARAMETER QuitAfterSeconds
  Seconds to run the main scene before exit. Default 2.

.PARAMETER Strict
  If set, exit 1 when log matches common failure patterns (SCRIPT ERROR, Failed to instantiate an autoload).

.EXAMPLE
  .\tools\run_runtime_smoke.ps1
  .\tools\run_runtime_smoke.ps1 -Strict -QuitAfterSeconds 3
#>
param(
	[string] $GodotExe = $env:GODOT_EXE,
	[string] $ProjectPath = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
	[int] $QuitAfterSeconds = 2,
	[switch] $Strict
)

$ErrorActionPreference = "Continue"
if (-not $GodotExe -or -not (Test-Path -LiteralPath $GodotExe)) {
	$GodotExe = "D:\program\Godot_v4.6.2-stable_win64.exe"
}
if (-not (Test-Path -LiteralPath $GodotExe)) {
	Write-Error "Godot executable not found. Set -GodotExe or `$env:GODOT_EXE."
	exit 2
}
if (-not (Test-Path -LiteralPath (Join-Path $ProjectPath "project.godot"))) {
	Write-Error "project.godot not found under: $ProjectPath"
	exit 2
}

$logFile = Join-Path $PSScriptRoot "last_smoke_log.txt"
$argList = @(
	"--headless",
	"--path", $ProjectPath,
	"--quit-after", [string]$QuitAfterSeconds
)
Write-Host "Running: $GodotExe $($argList -join ' ')"
& $GodotExe @argList 2>&1 | Tee-Object -FilePath $logFile
$code = $LASTEXITCODE
if ($null -eq $code) { $code = 0 }
Write-Host "`nExit code: $code"
Write-Host "Full log: $logFile"

if ($Strict) {
	$text = Get-Content -LiteralPath $logFile -Raw -ErrorAction SilentlyContinue
	if ($text -match "SCRIPT ERROR" -or $text -match "Failed to load script" -or $text -match "Failed to instantiate an autoload") {
		Write-Host "Strict mode: failures detected in log -> exit 1"
		exit 1
	}
}
exit $code
