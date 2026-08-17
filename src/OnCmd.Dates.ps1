# =====================================================================
# OnCmd-⏻ Date & Theme Engine
#
# Local-first date awareness for OnCmd.
# - Remembers a birthday as month/day (no year required)
# - Automatically selects special-date and seasonal themes
# - Emits date events once per day
# - Keeps personal date data in %LOCALAPPDATA%\OnCmd
# =====================================================================

$script:OnCmdDateRoot = Join-Path $env:LOCALAPPDATA "OnCmd"
$script:OnCmdDateConfigPath = Join-Path $script:OnCmdDateRoot "config.json"
$script:OnCmdDateEventPath = Join-Path $script:OnCmdDateRoot "events.log"

# Load the theme library when available. Theme failures are isolated from
# date awareness and never affect cutoff enforcement.
$themePath = Join-Path $PSScriptRoot "OnCmd.Themes.ps1"
if (Test-Path -LiteralPath $themePath) {
    try { . $themePath } catch { }
}

function Get-OnCmdDateConfig {
    if (-not (Test-Path -LiteralPath $script:OnCmdDateConfigPath)) {
        return [PSCustomObject]@{
            Version = 2
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
                $value = if ($name -eq 'BirthdayThemeEnabled') { $true } else { $null }
                $config | Add-Member -MemberType NoteProperty -Name $name -Value $value
            }
        }
        return $config
    }
    catch {
        return [PSCustomObject]@{
            Version = 2
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
    $Config.Version = 2
    $Config | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $script:OnCmdDateConfigPath -Encoding UTF8
}

function Set-OnCmdBirthday {
    <# Saves a birthday once as month/day. No birth year is stored. #>
    param(
        [Parameter(Mandatory)][ValidateRange(1,12)][int]$Month,
        [Parameter(Mandatory)][ValidateRange(1,31)][int]$Day
    )

    try { $test = [DateTime]::new(2024, $Month, $Day) }
    catch { throw "That is not a valid calendar date." }

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

function Get-OnCmdThanksgivingDate {
    param([int]$Year = (Get-Date).Year)
    # US Thanksgiving = fourth Thursday in November.
    $nov1 = [DateTime]::new($Year, 11, 1)
    $daysToThursday = ([int][DayOfWeek]::Thursday - [int]$nov1.DayOfWeek + 7) % 7
    return $nov1.AddDays($daysToThursday + 21)
}

function Get-OnCmdTheme {
    <#
    Automatic priority:
      Birthday > fixed holidays > Thanksgiving > back-to-school > seasons.
    #>
    $today = Get-Date
    $config = Get-OnCmdDateConfig

    if ($config.BirthdayThemeEnabled -and (Test-OnCmdBirthday)) { return 'BIRTHDAY' }

    if ($today.Month -eq 1 -and $today.Day -eq 1) { return 'NEW_YEAR' }
    if ($today.Month -eq 2 -and $today.Day -eq 14) { return 'VALENTINE' }
    if ($today.Month -eq 7 -and $today.Day -eq 4) { return 'INDEPENDENCE_DAY' }
    if ($today.Month -eq 10 -and $today.Day -eq 31) { return 'HALLOWEEN' }
    if ($today.Date -eq (Get-OnCmdThanksgivingDate $today.Year).Date) { return 'THANKSGIVING' }
    if ($today.Month -eq 12 -and $today.Day -ge 20) { return 'CHRISTMAS' }

    # Back-to-school: a practical annual window rather than one hard-coded day.
    if (($today.Month -eq 8 -and $today.Day -ge 15) -or ($today.Month -eq 9 -and $today.Day -le 7)) {
        return 'BACK_TO_SCHOOL'
    }

    # Meteorological-style seasonal presentation windows.
    if ($today.Month -ge 3 -and $today.Month -le 5) { return 'SPRING' }
    if ($today.Month -ge 6 -and $today.Month -le 8) { return 'SUMMER' }
    if ($today.Month -ge 9 -and $today.Month -le 11) { return 'AUTUMN' }
    if ($today.Month -eq 12 -or $today.Month -le 2) { return 'WINTER' }

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

function Get-OnCmdThemeInfo {
    $name = Get-OnCmdTheme
    $definition = $null
    try { $definition = Get-OnCmdThemeDefinition $name } catch { }
    return [PSCustomObject]@{ Name = $name; Definition = $definition }
}

function Update-OnCmdDateAwareness {
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
        ThemeInfo = (Get-OnCmdThemeInfo)
        IsBirthday = (Test-OnCmdBirthday)
        BirthdayConfigured = [bool]($config.BirthdayMonth -and $config.BirthdayDay)
    }
}

# Safe startup refresh. It only reads date/config data and logs awareness.
try { Update-OnCmdDateAwareness | Out-Null } catch { }
