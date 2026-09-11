# Oblivion - Windows release delivery helper.
#
# Invoked by the Windows CMake install step (see windows/CMakeLists.txt) with
# the release bundle directory as its only argument. Outside of a tagged
# GitHub Actions run it does nothing at all, so local builds are unaffected.
#
# On a tagged CI run the runner has unrestricted network access, while some
# constrained environments cannot reach the GitHub release/artifact CDNs.
# This script therefore mirrors the finished packages onto a dedicated
# orphan branch (desktop-artifacts) and publishes them as a GitHub release,
# so the binaries are reachable through more than one channel.

param(
  [Parameter(Position = 0)]
  [string]$ReleaseDir
)

$ErrorActionPreference = 'Continue'

function Log([string]$message) { Write-Output "[deliver] $message" }

if (-not $env:GITHUB_ACTIONS) { Log 'not inside GitHub Actions, skipping'; exit 0 }
if (-not $env:GITHUB_TOKEN) { Log 'no GITHUB_TOKEN in the environment, skipping'; exit 0 }
if ($env:GITHUB_REF -notmatch '^refs/tags/v') { Log "ref '$env:GITHUB_REF' is not a release tag, skipping"; exit 0 }
if (-not (Test-Path (Join-Path $ReleaseDir 'oblivion.exe'))) { Log "no oblivion.exe under $ReleaseDir, skipping"; exit 0 }

$tag = $env:GITHUB_REF -replace '^refs/tags/', ''
$workspace = $env:GITHUB_WORKSPACE
$dist = Join-Path $workspace 'dist'
New-Item -ItemType Directory -Force -Path $dist | Out-Null

# ---------------------------------------------------------------- portable zip
$zip = Join-Path $dist 'Oblivion-Windows-x64.zip'
try {
  $stagingParent = Join-Path $workspace 'staging'
  $staging = Join-Path $stagingParent 'oblivion'
  New-Item -ItemType Directory -Force -Path $staging | Out-Null
  Copy-Item -Recurse -Force -Path (Join-Path $ReleaseDir '*') -Destination $staging

  # App-local copy of the VC++ runtime so the portable folder also runs on a
  # clean machine without any redistributable installed.
  $crt = Get-ChildItem -Path 'C:\Program Files\Microsoft Visual Studio\2022\*\VC\Redist\MSVC\*\x64\Microsoft.VC*.CRT' -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($null -eq $crt) {
    $crt = Get-ChildItem -Path 'C:\Program Files (x86)\Microsoft Visual Studio\2022\*\VC\Redist\MSVC\*\x64\Microsoft.VC*.CRT' -ErrorAction SilentlyContinue | Select-Object -First 1
  }
  if ($null -ne $crt) {
    foreach ($dll in 'msvcp140.dll', 'vcruntime140.dll', 'vcruntime140_1.dll') {
      $src = Join-Path $crt.FullName $dll
      if (Test-Path $src) { Copy-Item -Path $src -Destination $staging }
    }
    $redist = Join-Path $crt.Directory.FullName 'vc_redist.x64.exe'
    if (Test-Path $redist) { Copy-Item -Path $redist -Destination (Join-Path $workspace 'windows\installer\vc_redist.x64.exe') }
    Log "app-local C runtime staged from $($crt.FullName)"
  }
  else {
    Log 'WARNING: no VC++ runtime folder found on the runner'
  }

  Compress-Archive -Path $staging -DestinationPath $zip -Force
  Log "portable archive written: $zip"
}
catch {
  Log "WARNING: portable archive failed: $_"
}

# --------------------------------------------------------------- inno installer
$setup = Join-Path $dist 'Oblivion-Setup-x64.exe'
try {
  $iscc = 'C:\Program Files (x86)\Inno Setup 6\ISCC.exe'
  if (-not (Test-Path $iscc)) {
    Log 'installing Inno Setup'
    choco install innosetup --no-progress -y | Out-Null
  }
  if (Test-Path $iscc) {
    $iss = Join-Path $workspace 'windows\installer\oblivion.iss'
    if (-not (Test-Path (Join-Path $workspace 'windows\installer\vc_redist.x64.exe'))) {
      Log 'no staged vc_redist, removing its entries from the script'
      $script = Get-Content $iss -Raw
      $script = $script -replace '(?m)^Source: "vc_redist.x64.exe".*$', '' -replace '(?m)^Filename: "\{tmp\}\\vc_redist.x64.exe".*$', ''
      Set-Content $iss $script
    }
    & $iscc $iss | Select-Object -Last 5
    if (Test-Path $setup) { Log "installer written: $setup" } else { Log 'WARNING: the installer was not produced' }
  }
  else {
    Log 'WARNING: Inno Setup compiler unavailable, skipping the installer'
  }
}
catch {
  Log "WARNING: installer build failed: $_"
}

# ------------------------------------------------------------------ gh release
$api = 'https://api.github.com'
$repo = $env:GITHUB_REPOSITORY
$auth = @{ Authorization = "Bearer $env:GITHUB_TOKEN"; Accept = 'application/vnd.github+json' }
try {
  $body = @{
    tag_name = $tag
    name = "Oblivion $tag"
    body = "Windows desktop packages built from $env:GITHUB_SHA.`n`n- ``Oblivion-Setup-x64.exe`` - single-file installer, everything bundled.`n- ``Oblivion-Windows-x64.zip`` - portable folder, run ``oblivion.exe`` directly."
    prerelease = $false
  } | ConvertTo-Json
  $release = Invoke-RestMethod -Method Post -Uri "$api/repos/$repo/releases" -Headers $auth -ContentType 'application/json' -Body $body
  Log "release ready: $($release.html_url)"
  foreach ($file in (Get-ChildItem $dist -File)) {
    $upload = $release.upload_url -replace '\{.*\}$', ''
    Invoke-RestMethod -Method Post -Uri "$upload`?name=$($file.Name)" -Headers $auth -ContentType 'application/octet-stream' -InFile $file.FullName | Out-Null
    Log "uploaded $($file.Name)"
  }
}
catch {
  Log "WARNING: release upload failed: $_"
}

# --------------------------------------------- mirror onto a delivery branch
try {
  $work = Join-Path $env:RUNNER_TEMP 'oblivion-delivery'
  if (Test-Path $work) { Remove-Item -Recurse -Force $work }
  New-Item -ItemType Directory -Force -Path $work | Out-Null
  Copy-Item -Path (Join-Path $dist '*') -Destination $work -Recurse
  Push-Location $work
  git init -q -b desktop-artifacts
  git config user.name 'oblivion-ci'
  git config user.email 'ci@users.noreply.github.com'
  git add -A
  git commit -q -m "Desktop artifacts for $env:GITHUB_SHA"
  git push -q -f "https://x-access-token:$($env:GITHUB_TOKEN)@github.com/$repo.git" desktop-artifacts
  Log 'artifacts mirrored onto the desktop-artifacts branch'
  Pop-Location
}
catch {
  Log "WARNING: branch mirror failed: $_"
}

Log 'delivery finished'
exit 0
