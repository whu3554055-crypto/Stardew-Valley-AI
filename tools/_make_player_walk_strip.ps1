$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing
$root = Split-Path -Parent $PSScriptRoot
$p = Join-Path $root "assets\sprites\characters\player.png"
$out = Join-Path $root "assets\sprites\characters\player_walk_3.png"
$src = [System.Drawing.Bitmap]::FromFile($p)
$w = $src.Width
$h = $src.Height
$dst = New-Object System.Drawing.Bitmap ($w * 3), $h
$g = [System.Drawing.Graphics]::FromImage($dst)
for ($i = 0; $i -lt 3; $i++) {
	$g.DrawImage($src, $i * $w, 0)
}
$dst.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose()
$dst.Dispose()
$src.Dispose()
Write-Host "Wrote $out (${w}x${h} x3)"
