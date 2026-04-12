param(
	[int]$Frames = 72
)

$ErrorActionPreference = "Stop"
$exe = $env:GODOT_CONSOLE
if (-not $exe) {
	$exe = "D:\program\Godot_v4.6.2-stable_win64_console.exe"
}
if (-not (Test-Path -LiteralPath $exe)) {
	Write-Error "Godot console exe not found: $exe. Set env GODOT_CONSOLE."
}

$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$strip = Join-Path $root "tools\_make_player_walk_strip.ps1"
if (Test-Path -LiteralPath $strip) {
	& $strip | Out-Null
}

$scenes = @(
	"res://scenes/world/world_town.tscn",
	"res://scenes/world/world_mine.tscn",
	"res://scenes/world/world_cave.tscn",
	"res://scenes/world/world_beach.tscn",
	"res://scenes/world/world_forest.tscn",
	"res://scenes/world/world_farm.tscn"
)

foreach ($s in $scenes) {
	Write-Host "---- $s ----"
	& $exe @("--headless", "--path", $root, "--scene", $s, "--quit-after", "$Frames")
	if ($LASTEXITCODE -ne 0) {
		exit $LASTEXITCODE
	}
}
Write-Host "All world shell smokes OK."
exit 0
