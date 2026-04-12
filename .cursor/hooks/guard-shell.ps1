# Cursor beforeShellExecution: block obvious attempts to stage/commit local AI secrets.
# stdin: JSON (shape may vary; fail open on parse errors).

$ErrorActionPreference = "Stop"

function Emit-Json($obj) {
	$obj | ConvertTo-Json -Compress -Depth 5
}

try {
	$raw = [Console]::In.ReadToEnd()
} catch {
	exit 0
}

if ([string]::IsNullOrWhiteSpace($raw)) {
	exit 0
}

try {
	$j = $raw | ConvertFrom-Json
} catch {
	exit 0
}

$cmd = ""
if ($null -ne $j.command) {
	$cmd = [string]$j.command
} elseif ($null -ne $j.shellCommand) {
	$cmd = [string]$j.shellCommand
}

if ([string]::IsNullOrWhiteSpace($cmd)) {
	exit 0
}

# Normalize for simple matching
$lc = $cmd.ToLowerInvariant()

if ($lc -notmatch "git\s+add|git\s+commit|git\s+-c") {
	exit 0
}

if ($cmd -match "ai_secrets\.json" -or $cmd -match "data[/\\]local[/\\]ai_secrets") {
	$out = [ordered]@{
		permission   = "deny"
		user_message = "Blocked: commands touching data/local/ai_secrets.json must not be run. File is gitignored and must not be committed."
		agent_message = "Hook denied shell: possible staging/commit of local AI secrets path."
	}
	Emit-Json $out
	exit 2
}

$allow = [ordered]@{ permission = "allow" }
Emit-Json $allow
exit 0
