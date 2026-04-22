$ErrorActionPreference = "Stop"

$godot = if ($env:GODOT_CONSOLE) { $env:GODOT_CONSOLE } else { "D:\program\Godot_v4.6.2-stable_win64_console.exe" }
$repoRoot = Split-Path -Parent $PSScriptRoot

Write-Host "[agentic-regression] Using Godot: $godot"

if (-not (Test-Path $godot)) {
    throw "Godot console executable not found: $godot"
}

Push-Location $repoRoot
try {
    Write-Host "[agentic-regression] Running schema translator tests..."
    & $godot --headless --path $repoRoot --script "res://tools/test_chain_schema_translator.gd"
    if ($LASTEXITCODE -ne 0) { throw "Schema translator test failed." }

    Write-Host "[agentic-regression] Running runtime registration tests..."
    & $godot --headless --path $repoRoot --script "res://tools/test_runtime_chain_registration.gd"
    if ($LASTEXITCODE -ne 0) { throw "Runtime registration test failed." }

    Write-Host "[agentic-regression] Running smoke startup..."
    & "$repoRoot\tools\run_headless_smoke.ps1"
    if ($LASTEXITCODE -ne 0) { throw "Headless smoke failed." }

    Write-Host "[agentic-regression] All checks passed."
}
finally {
    Pop-Location
}

