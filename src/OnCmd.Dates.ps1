# =====================================================================
# OnCmd-⏻ Date & Theme Engine
#
# Local-first date awareness for OnCmd.
# - Remembers a birthday as month/day (no year required)
# - Automatically selects a seasonal/special-date theme
# - Emits date events once per day
# - Keeps personal date data in %LOCALAPPDATA%\OnCmd
# =====================================================================

$script:OnCmdDateRoot = Join-Path $env:LOCALAPPDATA "OnCmd"
$script:OnCmdDateConfigPath = Join-Path $script:OnCmdDateRoot "config.json"
$script:OnCmdDateEventPath = Join-Path $script:OnCmdDateRoot "events.log"

function Get-OnCmdDateConfig {
    if (-not (Test-Path -LiteralPath $script:OnCmdDateConfigPath)) {
        return [PSCustomObject]@{
            Version = 1
            BirthdayMonth = $null
            BirthdayDay = $null
            BirthdayThemeEnabled = $true
            LastDateEvent = $null
        }
    }

    try {
        $config = Get-Content -LiteralPath $script:OnCmdDateConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json

        foreach ($name in @('BirthdayMonth','BirthdayDay','BirthdayThemeEnabled','LastDateEvent')) {
            if ($null -eq $config.PSObject.Properties[$name]) {
                $value = switch ($name) {
                    'BirthdayThemeEnabled' { $true }
                    default { $null }
                }
                $config | Add-Member -MemberType NoteProperty -Name $name -Value $value
            }
        }

        return $config
    }
    catch {
        return [PSCustomObject]@{
            Version = 1
            BirthdayMonth = $null
            BirthdayDay = $null
            BirthdayThemeEnabled = $true
            LastDateEvent = $null
        }
    }
}

function Save-OnCmdDateConfig {
    param([Parameter(Mandatory)][object]$Config)

    if (-not (Test-Path -LiteralPath $script:OnCmdDateRoot)) {
        New-Item -ItemType Directory -Path $script:OnCmdDateRoot -Force | Out-Null
    }

    $Config.Version = 1
    $Config | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $script:OnCmdDateConfigPath -Encoding UTF8
}

function Set-OnCmdBirthday {
    <#
    .SYNOPSIS
        Saves a birthday once as month/day.

    .EXAMPLE
        Set-OnCmdBirthday -Month 4 -Day 21
    #>
    param(
        [Parameter(Mandatory)][ValidateRange(1,12)][int]$Month,
        [Parameter(Mandatory)][ValidateRange(1,31)][int]$Day
    )

    try {
        $test = [DateTime]::new(2024, $Month, $Day)
    }
    catch {
        throw "That is not a valid calendar date."
    }

    $config = Get-OnCmdDateConfig
    $config.BirthdayMonth = $Month
    $config.BirthdayDay = $Day
    $config.BirthdayThemeEnabled = $true
    Save-OnCmdDateConfig $config

    Write-OnCmdDateEvent "BIRTHDAY_DATE_SET: $($test.ToString('MM-dd'))"
}

function Clear-OnCmdBirthday {
    $config = Get-OnCmdDateConfig
    $config.BirthdayMonth = $null
    $config.BirthdayDay = $null
    Save-OnCmdDateConfig $config
    Write-OnCmdDateEvent "BIRTHDAY_DATE_CLEARED"
}

function Test-OnCmdBirthday {
    $config = Get-OnCmdDateConfig
    if (-not $config.BirthdayMonth -or -not $config.BirthdayDay) { return $false }

    $today = Get-Date
    return ($today.Month -eq [int]$config.BirthdayMonth -and $today.Day -eq [int]$config.BirthdayDay)
}

function Get-OnCmdTheme {
    <#
    Returns the automatic theme for today's date.
    Birthday wins over seasonal themes.
    #>
    $today = Get-Date
    $config = Get-OnCmdDateConfig

    if ($config.BirthdayThemeEnabled -and (Test-OnCmdBirthday)) {
        return 'BIRTHDAY'
    }

    # Common seasonal themes. These are intentionally lightweight so the
    # terminal can change its personality without changing core behavior.
    if ($today.Month -eq 12 -and $today.Day -ge 20) { return 'WINTER_HOLIDAY' }
    if ($today.Month -eq 10 -and $today.Day -ge 20) { return 'HALLOWEEN' }
    if ($today.Month -eq 7 -and $today.Day -eq 4) { return 'INDEPENDENCE_DAY' }
    if ($today.Month -eq 2 -and $today.Day -eq 14) { return 'VALENTINE' }
    if ($today.Month -eq 1 -and $today.Day -eq 1) { return 'NEW_YEAR' }

    return 'DEFAULT'
}

function Write-OnCmdDateEvent {
    param([Parameter(Mandatory)][string]$Message)

    try {
        if (-not (Test-Path -LiteralPath $script:OnCmdDateRoot)) {
            New-Item -ItemType Directory -Path $script:OnCmdDateRoot -Force | Out-Null
        }
        $stamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
        Add-Content -LiteralPath $script:OnCmdDateEventPath -Value "$stamp | $Message" -Encoding UTF8
    }
    catch {
        # Date themes must never break OnCmd's cutoff/worker path.
    }
}

function Update-OnCmdDateAwareness {
    <#
    Call once during OnCmd startup or theme refresh.
    Returns a small object the terminal/UI can use.
    #>
    $today = Get-Date
    $config = Get-OnCmdDateConfig
    $theme = Get-OnCmdTheme
    $dateKey = $today.ToString('yyyy-MM-dd')

    if ($config.LastDateEvent -ne $dateKey) {
        Write-OnCmdDateEvent "DATE_AWARENESS: date=$dateKey;theme=$theme"
        $config.LastDateEvent = $dateKey
        Save-OnCmdDateConfig $config
    }

    return [PSCustomObject]@{
        Date = $today
        Theme = $theme
        IsBirthday = (Test-OnCmdBirthday)
        BirthdayConfigured = [bool]($config.BirthdayMonth -and $config.BirthdayDay)
    }
}

# Optional startup refresh when this file is dot-sourced.
# The call is safe and does not alter cutoff state.
try { Update-OnCmdDateAwareness | Out-Null } catch { }
