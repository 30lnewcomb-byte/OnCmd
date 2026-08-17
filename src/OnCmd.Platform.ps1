# ============================================================================
# ONCMD-⏻ PLATFORM ABSTRACTION
#
# Shared platform detection and native lock/sleep helpers.
# The cutoff/learning/date/theme logic should call these functions instead of
# hard-coding an operating-system command.
#
# Supported targets:
#   - Windows
#   - macOS
#   - Linux
#
# Windows remains the reference enforcement platform. macOS/Linux use their
# native session/power tools where available.
# ============================================================================

Set-StrictMode -Version Latest

function Get-OnCmdPlatform {
    if ($env:OS -eq 'Windows_NT') {
        return 'Windows'
    }

    if ($PSVersionTable.PSEdition -eq 'Core') {
        try {
            if ([System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform(
                    [System.Runtime.InteropServices.OSPlatform]::OSX)) {
                return 'macOS'
            }

            if ([System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform(
                    [System.Runtime.InteropServices.OSPlatform]::Linux)) {
                return 'Linux'
            }
        }
        catch {
        }
    }

    return 'Unknown'
}

function Get-OnCmdPlatformInfo {
    [PSCustomObject]@{
        Platform = Get-OnCmdPlatform
        PowerShellEdition = $PSVersionTable.PSEdition
        PowerShellVersion = $PSVersionTable.PSVersion.ToString()
        SupportsNativePower = (Get-OnCmdPlatform) -in @('Windows', 'macOS', 'Linux')
    }
}

function Invoke-OnCmdLock {
    [CmdletBinding()]
    param()

    switch (Get-OnCmdPlatform) {
        'Windows' {
            $result = Start-Process -FilePath 'rundll32.exe' -ArgumentList 'user32.dll,LockWorkStation' -PassThru -Wait
            if ($result.ExitCode -ne 0) {
                throw "Windows session lock failed with exit code $($result.ExitCode)."
            }
            return
        }

        'macOS' {
            $osascript = Get-Command osascript -ErrorAction Stop
            & $osascript.Source -e 'tell application "System Events" to keystroke "q" using {control down, command down}'
            if ($LASTEXITCODE -ne 0) {
                throw 'macOS session lock failed. Accessibility permission may be required for System Events.'
            }
            return
        }

        'Linux' {
            $loginctl = Get-Command loginctl -ErrorAction SilentlyContinue
            if ($loginctl) {
                & $loginctl.Source lock-session
                if ($LASTEXITCODE -eq 0) { return }
            }

            $xdg = Get-Command xdg-screensaver -ErrorAction SilentlyContinue
            if ($xdg) {
                & $xdg.Source lock
                if ($LASTEXITCODE -eq 0) { return }
            }

            $gnome = Get-Command gnome-screensaver-command -ErrorAction SilentlyContinue
            if ($gnome) {
                & $gnome.Source -l
                if ($LASTEXITCODE -eq 0) { return }
            }

            throw 'No supported Linux session-lock command was found.'
        }

        default {
            throw 'OnCmd does not recognize this operating system.'
        }
    }
}

function Invoke-OnCmdSleep {
    [CmdletBinding()]
    param()

    switch (Get-OnCmdPlatform) {
        'Windows' {
            throw 'Windows sleep remains owned by the existing Windows power worker. Do not call this helper from that worker.'
        }

        'macOS' {
            $pmset = Get-Command pmset -ErrorAction Stop
            & $pmset.Source sleepnow
            if ($LASTEXITCODE -ne 0) {
                throw "macOS sleep request failed with exit code $LASTEXITCODE."
            }
            return
        }

        'Linux' {
            $systemctl = Get-Command systemctl -ErrorAction SilentlyContinue
            if ($systemctl) {
                & $systemctl.Source suspend
                if ($LASTEXITCODE -eq 0) { return }
            }

            $loginctl = Get-Command loginctl -ErrorAction SilentlyContinue
            if ($loginctl) {
                & $loginctl.Source suspend
                if ($LASTEXITCODE -eq 0) { return }
            }

            throw 'No supported Linux suspend command was found.'
        }

        default {
            throw 'OnCmd does not recognize this operating system.'
        }
    }
}

function Test-OnCmdPlatformCapabilities {
    $platform = Get-OnCmdPlatform

    [PSCustomObject]@{
        Platform = $platform
        Lock = switch ($platform) {
            'Windows' { $true }
            'macOS' { [bool](Get-Command osascript -ErrorAction SilentlyContinue) }
            'Linux' { [bool]((Get-Command loginctl -ErrorAction SilentlyContinue) -or (Get-Command xdg-screensaver -ErrorAction SilentlyContinue)) }
            default { $false }
        }
        Sleep = switch ($platform) {
            'Windows' { $true }
            'macOS' { [bool](Get-Command pmset -ErrorAction SilentlyContinue) }
            'Linux' { [bool]((Get-Command systemctl -ErrorAction SilentlyContinue) -or (Get-Command loginctl -ErrorAction SilentlyContinue)) }
            default { $false }
        }
    }
}
