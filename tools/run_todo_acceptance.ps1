#Requires -Version 5.1
<#
.SYNOPSIS
  Minimal automated batch aligned with docs/03-研发管理/11-TODO已实现项验收清单.md:
  - Required data/script paths exist
  - World shell headless smokes
  - Main scene headless smoke
  - GUT subset (stable unit scripts only; excludes known-broken season tests)

.PARAMETER SkipGut
  Skip GUT step (smokes only).

.EXAMPLE
  .\tools\run_todo_acceptance.ps1
#>
param(
	[switch]$SkipGut
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

$required = @(
	"data/presentation/immersion_config.json",
	"data/recipes/cooking.json",
	"data/recipes/crafting.json",
	"data/buildings/upgrades.json",
	"data/farm/crops.json",
	"data/shop/stock.json",
	"autoload/fishing_system.gd",
	"autoload/mining_system.gd",
	"autoload/cooking_system.gd",
	"autoload/crafting_system.gd",
	"autoload/ai_economy_system.gd",
	"autoload/ai_quest_system.gd",
	"autoload/npc_plugin_manager.gd",
	"scripts/combat/mine_combat_controller.gd",
	"plugins/social_dynamics_plugin.gd"
)
foreach ($rel in $required) {
	$p = Join-Path $root $rel
	if (-not (Test-Path -LiteralPath $p)) {
		Write-Error "TODO acceptance: missing required path $rel"
	}
}
Write-Host "TODO acceptance: required files OK."

& (Join-Path $PSScriptRoot "run_world_shells_smoke.ps1") -Frames 32
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

& (Join-Path $PSScriptRoot "run_headless_smoke.ps1") -Frames 96
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

if (-not $SkipGut) {
	$gutScript = Join-Path $root "addons\gut\gut_cmdln.gd"
	if (-not (Test-Path -LiteralPath $gutScript)) {
		Write-Error "GUT not found at $gutScript"
	}
	$gutTests = @(
		"res://tests/unit/test_ai_quest_objective_verify.gd",
		"res://tests/unit/test_ai_quest_system.gd",
		"res://tests/unit/test_item_database_reward_items.gd",
		"res://tests/unit/test_managed_chain_system.gd",
		"res://tests/unit/test_quest_system.gd"
	)
	$argList = @(
		"--headless",
		"--path", $root,
		"-s", "res://addons/gut/gut_cmdln.gd",
		"--",
		"-gconfig="
	)
	foreach ($t in $gutTests) {
		$argList += "-gtest=$t"
	}
	$argList += "-gexit"
	Write-Host "Running GUT subset: $($gutTests.Count) scripts"
	& $exe @argList
	if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

Write-Host "TODO acceptance batch: all steps OK."
exit 0
