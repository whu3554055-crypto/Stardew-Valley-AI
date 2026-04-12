param(
	[int]$Frames = 120,
	[string]$Scene = ""
)

$ErrorActionPreference = "Stop"
$exe = $env:GODOT_CONSOLE
if (-not $exe) {
	$exe = "D:\program\Godot_v4.6.2-stable_win64_console.exe"
}
if (-not (Test-Path -LiteralPath $exe)) {
	Write-Error "Godot console exe not found: $exe. Set env GODOT_CONSOLE to your Godot 4.x *_console.exe."
}

$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$args = @("--headless", "--path", $root, "--quit-after", "$Frames")
if ($Scene) {
	$args = @("--headless", "--path", $root, "--scene", $Scene, "--quit-after", "$Frames")
}

& $exe @args
exit $LASTEXITCODE
