# =====================================================================
# OnCmd-⏻ Theme Library
#
# Pure presentation data. Themes never control cutoff/enforcement logic.
# =====================================================================

function Get-OnCmdThemeLibrary {
    return [ordered]@{
        DEFAULT = [PSCustomObject]@{ Name = 'OnCmd Default'; Icon = '⏻'; Foreground = 'White'; Accent = 'Cyan'; Description = 'Standard OnCmd terminal theme.' }
        BIRTHDAY = [PSCustomObject]@{ Name = 'Birthday'; Icon = '🎂'; Foreground = 'White'; Accent = 'Magenta'; Description = 'Birthday celebration theme.' }
        HALLOWEEN = [PSCustomObject]@{ Name = 'Halloween'; Icon = '🎃'; Foreground = 'Yellow'; Accent = 'DarkYellow'; Description = 'Spooky Halloween theme.' }
        THANKSGIVING = [PSCustomObject]@{ Name = 'Thanksgiving'; Icon = '🦃'; Foreground = 'Yellow'; Accent = 'DarkYellow'; Description = 'Thanksgiving theme.' }
        CHRISTMAS = [PSCustomObject]@{ Name = 'Christmas'; Icon = '🎄'; Foreground = 'Green'; Accent = 'Red'; Description = 'Christmas theme.' }
        NEW_YEAR = [PSCustomObject]@{ Name = 'New Year'; Icon = '🎆'; Foreground = 'White'; Accent = 'Cyan'; Description = 'New Year celebration theme.' }
        VALENTINE = [PSCustomObject]@{ Name = 'Valentine'; Icon = '❤️'; Foreground = 'Magenta'; Accent = 'Red'; Description = 'Valentine theme.' }
        SPRING = [PSCustomObject]@{ Name = 'Spring'; Icon = '🌸'; Foreground = 'Magenta'; Accent = 'Green'; Description = 'Spring seasonal theme.' }
        SUMMER = [PSCustomObject]@{ Name = 'Summer'; Icon = '☀️'; Foreground = 'Yellow'; Accent = 'Cyan'; Description = 'Summer seasonal theme.' }
        AUTUMN = [PSCustomObject]@{ Name = 'Autumn'; Icon = '🍂'; Foreground = 'Yellow'; Accent = 'DarkYellow'; Description = 'Autumn seasonal theme.' }
        WINTER = [PSCustomObject]@{ Name = 'Winter'; Icon = '❄️'; Foreground = 'White'; Accent = 'Cyan'; Description = 'Winter seasonal theme.' }
        INDEPENDENCE_DAY = [PSCustomObject]@{ Name = 'Independence Day'; Icon = '🇺🇸'; Foreground = 'White'; Accent = 'Red'; Description = 'Independence Day theme.' }
        BACK_TO_SCHOOL = [PSCustomObject]@{ Name = 'Back to School'; Icon = '🎒'; Foreground = 'Cyan'; Accent = 'Yellow'; Description = 'Back-to-school theme.' }
    }
}

function Get-OnCmdThemeDefinition {
    param([Parameter(Mandatory)][string]$ThemeName)
    $library = Get-OnCmdThemeLibrary
    if ($library.Contains($ThemeName)) { return $library[$ThemeName] }
    return $library.DEFAULT
}

function Set-OnCmdConsoleTheme {
    param([Parameter(Mandatory)][string]$ThemeName)
    $theme = Get-OnCmdThemeDefinition $ThemeName
    try {
        $Host.UI.RawUI.ForegroundColor = [System.Enum]::Parse([ConsoleColor], $theme.Foreground)
    } catch { }
    return $theme
}

function Get-OnCmdThemeNames {
    return @(Get-OnCmdThemeLibrary).Keys
}
