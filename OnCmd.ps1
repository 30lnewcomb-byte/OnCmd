# ============================================================================
# ONCMD-⏻ CLI ENTRYPOINT
# Lightweight cross-platform command surface.
# ============================================================================

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Command = 'status',

    [Parameter(Position = 1, ValueFromRemainingArguments = $true)]
    [string[]]$Arguments
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path

function Load-OnCmdModule {
    param([Parameter(Mandatory)][string]$Name)
    $path = Join-Path (Join-Path $Root 'src') $Name
    if (-not (Test-Path -LiteralPath $path)) { throw "OnCmd module not found: $path" }
    . $path
}

Load-OnCmdModule 'OnCmd.Themes.ps1'
Load-OnCmdModule 'OnCmd.Dates.ps1'
Load-OnCmdModule 'OnCmd.Platform.ps1'

function Show-OnCmdBanner {
    Write-Host ''
    Write-Host '  +===============================================================+' -ForegroundColor Cyan
    Write-Host '  |                         O N C M D - [POWER]                 |' -ForegroundColor Cyan
    Write-Host '  |                    DIGITAL BOUNDARY AGENT                   |' -ForegroundColor Cyan
    Write-Host '  +===============================================================+' -ForegroundColor Cyan
    Write-Host ''
}

function Show-OnCmdStatus {
    $dateInfo = Update-OnCmdDateAwareness
    $platform = Get-OnCmdPlatformInfo
    $theme = Get-OnCmdThemeDefinition $dateInfo.Theme

    Show-OnCmdBanner
    Write-Host "  Date:     $($dateInfo.Date.ToString('yyyy-MM-dd'))"
    Write-Host "  Platform: $($platform.Platform)"
    Write-Host "  PowerShell: $($platform.PowerShellEdition) $($platform.PowerShellVersion)"
    Write-Host "  Theme:    $($theme.Name) $($theme.Icon)" -ForegroundColor $theme.Accent
    Write-Host "  Birthday: $(if ($dateInfo.BirthdayConfigured) { 'configured' } else { 'not configured' })"
    Write-Host '  Engine:   date/theme awareness ready' -ForegroundColor Green
    Write-Host ''
}

switch ($Command.ToLowerInvariant()) {
    'status' { Show-OnCmdStatus }
    'date' {
        $info = Update-OnCmdDateAwareness
        Write-Host "Date: $($info.Date.ToString('dddd, MMMM d, yyyy'))"
        Write-Host "Theme: $($info.Theme)"
    }
    'theme' {
        $info = Update-OnCmdDateAwareness
        $theme = Get-OnCmdThemeDefinition $info.Theme
        Write-Host "$($theme.Icon) $($theme.Name) — $($theme.Description)" -ForegroundColor $theme.Accent
    }
    'themes' {
        Get-OnCmdThemeNames | ForEach-Object { Write-Host "  $_" }
    }
    'events' {
        Get-OnCmdEventPreferences | Format-List
    }
    'birthday' {
        if ($Arguments.Count -eq 2 -and $Arguments[0] -match '^\d+$' -and $Arguments[1] -match '^\d+$') {
            Set-OnCmdBirthday -Month ([int]$Arguments[0]) -Day ([int]$Arguments[1])
            Write-Host 'Birthday saved. It will repeat yearly.' -ForegroundColor Green
        }
        elseif ($Arguments.Count -eq 1 -and $Arguments[0] -eq 'clear') {
            Clear-OnCmdBirthday
            Write-Host 'Birthday cleared.' -ForegroundColor Yellow
        }
        else {
            $config = Get-OnCmdDateConfig
            if ($config.BirthdayMonth -and $config.BirthdayDay) {
                Write-Host ("Birthday: {0:00}-{1:00}" -f [int]$config.BirthdayMonth,[int]$config.BirthdayDay)
            } else { Write-Host 'Birthday: not configured.' }
        }
    }
    'help' {
        Show-OnCmdBanner
        Write-Host '  oncmd status' -ForegroundColor Green
        Write-Host '  oncmd date' -ForegroundColor Green
        Write-Host '  oncmd theme' -ForegroundColor Green
        Write-Host '  oncmd themes' -ForegroundColor Green
        Write-Host '  oncmd events' -ForegroundColor Green
        Write-Host '  oncmd birthday MM DD' -ForegroundColor Green
        Write-Host '  oncmd birthday clear' -ForegroundColor Green
    }
    default { throw "Unknown OnCmd command '$Command'. Run 'oncmd help'." }
}
