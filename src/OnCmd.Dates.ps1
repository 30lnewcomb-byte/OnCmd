# =====================================================================
# OnCmd-⏻ Date & Theme Engine
#
# Local-first date awareness for OnCmd.
# Dates are universal; celebrations are opt-in.
# Theme selection never controls cutoff enforcement.
# =====================================================================

$script:OnCmdDateRoot = Join-Path $env:LOCALAPPDATA "OnCmd"
$script:OnCmdDateConfigPath = Join-Path $script:OnCmdDateRoot "config.json"
$script:OnCmdDateEventPath = Join-Path $script:OnCmdDateRoot "events.log"

$themePath = Join-Path $PSScriptRoot "OnCmd.Themes.ps1"
if (Test-Path -LiteralPath $themePath) { try { . $themePath } catch { } }

$script:OnCmdBuiltInEvents = [ordered]@{
    NewYear = [PSCustomObject]@{ Month = 1; Day = 1; Theme = 'NEW_YEAR'; Label = 'New Year' }
    Valentine = [PSCustomObject]@{ Month = 2; Day = 14; Theme = 'VALENTINE'; Label = 'Valentine' }
    IndependenceDay = [PSCustomObject]@{ Month = 7; Day = 4; Theme = 'INDEPENDENCE_DAY'; Label = 'Independence Day' }
    Halloween = [PSCustomObject]@{ Month = 10; Day = 31; Theme = 'HALLOWEEN'; Label = 'Halloween' }
    Christmas = [PSCustomObject]@{ Month = 12; Day = 25; Theme = 'CHRISTMAS'; Label = 'Christmas' }
}

function Get-OnCmdDateConfig {
    $defaults = [ordered]@{
        Version = 3
        DateAwarenessEnabled = $true
        BirthdayMonth = $null
        BirthdayDay = $null
        BirthdayThemeEnabled = $true
        Events = [ordered]@{
            NewYear = $false
            Valentine = $false
            IndependenceDay = $false
            Halloween = $false
            Thanksgiving = $false
            Christmas = $false
            BackToSchool = $false
            Spring = $false
            Summer = $false
            Autumn = $false
            Winter = $false
        }
        CustomEvents = @()
        LastDateEvent = $null
    }

    if (-not (Test-Path -LiteralPath $script:OnCmdDateConfigPath)) {
        return [PSCustomObject]$defaults
    }

    try {
        $config = Get-Content -LiteralPath $script:OnCmdDateConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json
        foreach ($name in $defaults.Keys) {
            if ($null -eq $config.PSObject.Properties[$name]) {
                $config | Add-Member -MemberType NoteProperty -Name $name -Value $defaults[$name]
            }
        }
        if ($null -eq $config.Events) { $config.Events = [PSCustomObject]$defaults.Events }
        foreach ($eventName in $defaults.Events.Keys) {
            if ($null -eq $config.Events.PSObject.Properties[$eventName]) {
                $config.Events | Add-Member -MemberType NoteProperty -Name $eventName -Value $false
            }
        }
        if ($null -eq $config.CustomEvents) { $config.CustomEvents = @() }
        return $config
    }
    catch {
        return [PSCustomObject]$defaults
    }
}

function Save-OnCmdDateConfig {
    param([Parameter(Mandatory)][object]$Config)
    if (-not (Test-Path -LiteralPath $script:OnCmdDateRoot)) { New-Item -ItemType Directory -Path $script:OnCmdDateRoot -Force | Out-Null }
    $Config.Version = 3
    $Config | ConvertTo-Json -Depth 15 | Set-Content -LiteralPath $script:OnCmdDateConfigPath -Encoding UTF8
}

function Set-OnCmdBirthday {
    param([Parameter(Mandatory)][ValidateRange(1,12)][int]$Month,[Parameter(Mandatory)][ValidateRange(1,31)][int]$Day)
    try { $test = [DateTime]::new(2024, $Month, $Day) } catch { throw "That is not a valid calendar date." }
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

function Set-OnCmdEventPreference {
    param([Parameter(Mandatory)][string]$Name,[Parameter(Mandatory)][bool]$Enabled)
    $config = Get-OnCmdDateConfig
    $property = $config.Events.PSObject.Properties[$Name]
    if ($null -eq $property) { throw "Unknown built-in event '$Name'." }
    $config.Events.$Name = $Enabled
    Save-OnCmdDateConfig $config
    Write-OnCmdDateEvent ("EVENT_PREFERENCE: {0}={1}" -f $Name,$Enabled)
}

function Get-OnCmdEventPreferences {
    $config = Get-OnCmdDateConfig
    return $config.Events
}

function Add-OnCmdCustomEvent {
    param([Parameter(Mandatory)][string]$Name,[Parameter(Mandatory)][ValidateRange(1,12)][int]$Month,[Parameter(Mandatory)][ValidateRange(1,31)][int]$Day,[string]$Theme = 'DEFAULT',[bool]$Enabled = $true)
    try { [void][DateTime]::new(2024,$Month,$Day) } catch { throw "That is not a valid calendar date." }
    $config = Get-OnCmdDateConfig
    $existing = @($config.CustomEvents | Where-Object { $_.Name -eq $Name })
    if ($existing.Count -gt 0) { throw "A custom event named '$Name' already exists." }
    $config.CustomEvents = @($config.CustomEvents) + [PSCustomObject]@{ Name=$Name; Month=$Month; Day=$Day; Theme=$Theme; Enabled=$Enabled }
    Save-OnCmdDateConfig $config
    Write-OnCmdDateEvent "CUSTOM_EVENT_ADDED: $Name=$($Month.ToString('00'))-$($Day.ToString('00'))"
}

function Remove-OnCmdCustomEvent {
    param([Parameter(Mandatory)][string]$Name)
    $config = Get-OnCmdDateConfig
    $before = @($config.CustomEvents).Count
    $config.CustomEvents = @($config.CustomEvents | Where-Object { $_.Name -ne $Name })
    Save-OnCmdDateConfig $config
    if ($config.CustomEvents.Count -lt $before) { Write-OnCmdDateEvent "CUSTOM_EVENT_REMOVED: $Name"; return $true }
    return $false
}

function Get-OnCmdThanksgivingDate {
    param([int]$Year = (Get-Date).Year)
    $nov1 = [DateTime]::new($Year,11,1)
    $daysToThursday = ([int][DayOfWeek]::Thursday - [int]$nov1.DayOfWeek + 7) % 7
    return $nov1.AddDays($daysToThursday + 21)
}

function Test-OnCmdFixedEvent {
    param([string]$Name,[DateTime]$Date)
    $config = Get-OnCmdDateConfig
    if ($config.Events.$Name -ne $true) { return $null }
    if ($script:OnCmdBuiltInEvents.Contains($Name)) {
        $event = $script:OnCmdBuiltInEvents[$Name]
        if ($Date.Month -eq $event.Month -and $Date.Day -eq $event.Day) { return $event.Theme }
    }
    if ($Name -eq 'Thanksgiving' -and $Date.Date -eq (Get-OnCmdThanksgivingDate $Date.Year).Date) { return 'THANKSGIVING' }
    return $null
}

function Get-OnCmdTheme {
    $today = Get-Date
    $config = Get-OnCmdDateConfig

    # Explicit personal configuration has highest priority.
    if ($config.BirthdayThemeEnabled -and (Test-OnCmdBirthday)) { return 'BIRTHDAY' }

    foreach ($eventName in @('NewYear','Valentine','IndependenceDay','Halloween','Thanksgiving','Christmas')) {
        $theme = Test-OnCmdFixedEvent -Name $eventName -Date $today
        if ($theme) { return $theme }
    }

    foreach ($custom in @($config.CustomEvents)) {
        if ($custom.Enabled -eq $true -and $today.Month -eq [int]$custom.Month -and $today.Day -eq [int]$custom.Day) { return [string]$custom.Theme }
    }

    if ($config.Events.BackToSchool -eq $true -and (($today.Month -eq 8 -and $today.Day -ge 15) -or ($today.Month -eq 9 -and $today.Day -le 7))) { return 'BACK_TO_SCHOOL' }
    if ($config.Events.Spring -eq $true -and $today.Month -ge 3 -and $today.Month -le 5) { return 'SPRING' }
    if ($config.Events.Summer -eq $true -and $today.Month -ge 6 -and $today.Month -le 8) { return 'SUMMER' }
    if ($config.Events.Autumn -eq $true -and $today.Month -ge 9 -and $today.Month -le 11) { return 'AUTUMN' }
    if ($config.Events.Winter -eq $true -and ($today.Month -eq 12 -or $today.Month -le 2)) { return 'WINTER' }

    return 'DEFAULT'
}

function Write-OnCmdDateEvent {
    param([Parameter(Mandatory)][string]$Message)
    try {
        if (-not (Test-Path -LiteralPath $script:OnCmdDateRoot)) { New-Item -ItemType Directory -Path $script:OnCmdDateRoot -Force | Out-Null }
        $stamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
        Add-Content -LiteralPath $script:OnCmdDateEventPath -Value "$stamp | $Message" -Encoding UTF8
    } catch { }
}

function Get-OnCmdThemeInfo {
    $name = Get-OnCmdTheme
    $definition = $null
    try { $definition = Get-OnCmdThemeDefinition $name } catch { }
    return [PSCustomObject]@{ Name=$name; Definition=$definition }
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
        Date=$today
        Theme=$theme
        ThemeInfo=(Get-OnCmdThemeInfo)
        IsBirthday=(Test-OnCmdBirthday)
        BirthdayConfigured=[bool]($config.BirthdayMonth -and $config.BirthdayDay)
        EventPreferences=$config.Events
        CustomEvents=@($config.CustomEvents)
    }
}

try { Update-OnCmdDateAwareness | Out-Null } catch { }
