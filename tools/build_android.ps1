# Builds the signed Play Store AAB and a sideload APK with the release keystore in keystore/.
# Usage (repo root): powershell -ExecutionPolicy Bypass -File tools\build_android.ps1 [-Godot <path>]
param([string] $Godot = "godot")
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$props = @{}
Get-Content "$root\keystore\keystore.properties" | Where-Object { $_ -match '^\w+=' } | ForEach-Object {
	$k, $v = $_ -split '=', 2; $props[$k] = $v
}
$env:GODOT_ANDROID_KEYSTORE_RELEASE_PATH = (Resolve-Path "$root\keystore\$($props.storeFile)").Path
$env:GODOT_ANDROID_KEYSTORE_RELEASE_USER = $props.keyAlias
$env:GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD = $props.storePassword
$proj = Get-Content "$root\game\project.godot" -Raw
$ver = [regex]::Match($proj, 'config/version="([^"]+)"').Groups[1].Value
# Production guard: the AdMob plugin falls back to Google's test app id when none is set.
$appId = [regex]::Match($proj, 'general/android/app_id="([^"]+)"').Groups[1].Value
if ($appId -eq "" -or $proj -match '3940256099942544') {
	throw "AdMob masih memakai ID tes. Isi admob/general/android/app_id dan mahasigma/ads/*_unit di game/project.godot dengan ID Mahasigma."
}
New-Item -ItemType Directory -Force "$root\build" | Out-Null
foreach ($job in @(@("Android Play (AAB)", "aab"), @("Android", "apk"))) {
	$out = "$root\build\MahasigmaSimulator-v$ver.$($job[1])"
	Write-Host "== $($job[0]) -> $out"
	# WaitForExit, not -Wait: the Gradle daemon outlives Godot and -Wait would block on it.
	$p = Start-Process -FilePath $Godot -PassThru `
		-ArgumentList "--headless --path `"$root\game`" --export-release `"$($job[0])`" `"$out`"" `
		-RedirectStandardOutput "$root\build\export-$($job[1]).log" -RedirectStandardError "$root\build\export-$($job[1]).err"
	$p.WaitForExit()
	if (-not (Test-Path $out)) { Get-Content "$root\build\export-$($job[1]).log", "$root\build\export-$($job[1]).err" -Tail 40; throw "export failed: $($job[0])" }
	Write-Host ("   {0:N1} MB" -f ((Get-Item $out).Length / 1MB))
}
