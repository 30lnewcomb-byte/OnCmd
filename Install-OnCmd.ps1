# ============================================================================
# ONCMD-⏻ BOOTSTRAP INSTALLER
# One script for a clean machine: fetch, verify, install a user launcher.
# ============================================================================

$ErrorActionPreference = 'Stop'
$RepoUrl = 'https://github.com/30lnewcomb-byte/OnCmd.git'
$InstallRoot = Join-Path $env:LOCALAPPDATA 'OnCmd'
$RepoRoot = Join-Path $InstallRoot 'repo'
$LauncherRoot = Join-Path $InstallRoot 'bin'
$LauncherPath = Join-Path $LauncherRoot 'oncmd.cmd'

function Write-OnCmd { param([string]$Text, [ConsoleColor]$Color = [ConsoleColor]::White) Write-Host $Text -ForegroundColor $Color }

Write-OnCmd ''
Write-OnCmd '  +===============================================================+' Cyan
Write-OnCmd '  |                 ONCMD-⏻ BOOTSTRAP INSTALLER                |' Cyan
Write-OnCmd '  +===============================================================+' Cyan
Write-OnCmd ''

$git = Get-Command git.exe -ErrorAction SilentlyContinue
if (-not $git) {
    Write-OnCmd '  [FAIL] Git was not found.' Red
    Write-OnCmd '         Install Git for Windows, then run this installer again.' Yellow
    exit 1
}

New-Item -ItemType Directory -Path $InstallRoot -Force | Out-Null
New-Item -ItemType Directory -Path $LauncherRoot -Force | Out-Null

if (Test-Path -LiteralPath $RepoRoot) {
    if (Test-Path -LiteralPath (Join-Path $RepoRoot '.git')) {
        Write-OnCmd '  [1/5] Existing OnCmd repository found.' Cyan
        & $git.Source -C $RepoRoot pull --ff-only
        if ($LASTEXITCODE -ne 0) {
            Write-OnCmd '  [WARN] Existing repository could not be fast-forwarded.' Yellow
            Write-OnCmd '        No files were deleted or reset.' Yellow
        }
    } else {
        Write-OnCmd '  [FAIL] Installation directory exists but is not an OnCmd Git repository.' Red
        Write-OnCmd "         $RepoRoot" Yellow
        exit 1
    }
} else {
    Write-OnCmd '  [1/5] Downloading OnCmd from GitHub...' Cyan
    & $git.Source clone $RepoUrl $RepoRoot
    if ($LASTEXITCODE -ne 0) { throw 'Git clone failed.' }
}

Write-OnCmd '  [2/5] Verifying project...' Cyan
$required = @(
    'README.md',
    'LICENSE',
    'OnCmd.ps1',
    'src\OnCmd.Platform.ps1',
    'src\OnCmd.Dates.ps1',
    'src\OnCmd.Themes.ps1'
)
$missing = @($required | Where-Object { -not (Test-Path -LiteralPath (Join-Path $RepoRoot $_)) })
if ($missing.Count -gt 0) {
    Write-OnCmd '  [FAIL] Required files are missing:' Red
    $missing | ForEach-Object { Write-OnCmd "         $_" Red }
    exit 1
}
Write-OnCmd '        [ OK ] Repository structure verified.' Green

Write-OnCmd '  [3/5] Creating OnCmd launcher...' Cyan
$launcher = @'
@echo off
set "ONCMD_ROOT=%LOCALAPPDATA%\OnCmd\repo"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%ONCMD_ROOT%\OnCmd.ps1" %*
exit /b %ERRORLEVEL%
'@
Set-Content -LiteralPath $LauncherPath -Value $launcher -Encoding ASCII
Write-OnCmd '        [ OK ] Launcher created.' Green

Write-OnCmd '  [4/5] Configuring user command path...' Cyan
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
$pathEntries = if ($userPath) { @($userPath -split ';' | Where-Object { $_ }) } else { @() }
if ($pathEntries -notcontains $LauncherRoot) {
    [Environment]::SetEnvironmentVariable('Path', (($pathEntries + $LauncherRoot) -join ';'), 'User')
    Write-OnCmd '        [ OK ] Added OnCmd bin directory to user PATH.' Green
} else {
    Write-OnCmd '        [ OK ] User PATH already contains OnCmd bin.' Green
}

Write-OnCmd '  [5/5] Running final checks...' Cyan
$checks = @(
    (Test-Path -LiteralPath $RepoRoot),
    (Test-Path -LiteralPath $LauncherPath),
    (Test-Path -LiteralPath (Join-Path $RepoRoot 'OnCmd.ps1')),
    (Test-Path -LiteralPath (Join-Path $RepoRoot 'src\OnCmd.Dates.ps1')),
    (Test-Path -LiteralPath (Join-Path $RepoRoot 'src\OnCmd.Themes.ps1')),
    (Test-Path -LiteralPath (Join-Path $RepoRoot 'src\OnCmd.Platform.ps1'))
)
if ($checks -contains $false) { throw 'One or more final installation checks failed.' }

Write-OnCmd ''
Write-OnCmd '  +===============================================================+' Cyan
Write-OnCmd '  |                    ONCMD-⏻ READY                            |' Green
Write-OnCmd '  +===============================================================+' Cyan
Write-OnCmd ''
Write-OnCmd "  Installed repository: $RepoRoot" White
Write-OnCmd "  Launcher:             $LauncherPath" White
Write-OnCmd ''
Write-OnCmd '  IMPORTANT: Open a NEW PowerShell window for the updated PATH.' Yellow
Write-OnCmd ''
Write-OnCmd '  Then try:' White
Write-OnCmd '      oncmd status' Green
Write-OnCmd '      oncmd help' Green
Write-OnCmd ''
Write-OnCmd '  OnCmd bootstrap complete.' Cyan
