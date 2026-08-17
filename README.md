# OnCmd-⏻

<p align="center">
  <img src="assets/oncmd-art.svg" alt="Colorful OnCmd Digital Boundary Agent artwork" width="900">
</p>

```text
  +==========================================================================+
  |                         O N C M D - [POWER]                             |
  |                    DIGITAL BOUNDARY AGENT                              |
  +==========================================================================+

         ◆ LOCAL-FIRST    ◆ PERSISTENT    ◆ EVENT-DRIVEN
```

**Local-first Windows digital boundary agent.**

OnCmd is a PowerShell-based Windows automation project built around a simple idea: enforce a user-defined digital cutoff without depending on a cloud service.

## 🚀 One-command setup

You do **not** need to manually create the repository's folders or copy its scripts around.

On a Windows machine with **Git for Windows** installed, open PowerShell and run:

```powershell
irm https://raw.githubusercontent.com/30lnewcomb-byte/OnCmd/main/Install-OnCmd.ps1 | iex
```

The bootstrap installer will:

1. Create `%LOCALAPPDATA%\OnCmd`.
2. Clone OnCmd from GitHub, or update an existing OnCmd checkout with a fast-forward pull.
3. Verify the required project files.
4. Create the `oncmd` launcher.
5. Add the launcher directory to the current user's PATH without requiring administrator rights.
6. Run final installation checks.

After the installer finishes, open a **new PowerShell window** so Windows picks up the updated PATH, then run:

```powershell
oncmd
```

The installer prepares the system but does **not** silently enable voice or start enforcement on a fresh installation.

If Git is not installed, install Git for Windows first and rerun the bootstrapper.

## 🎨 Project Art

OnCmd has a dedicated colorful terminal-inspired project banner in [`assets/oncmd-art.svg`](assets/oncmd-art.svg). Art is an important part of the project because its creator has a genuine passion for art and enjoys bringing that creative side into technical projects. The goal is for OnCmd to feel both engineered and expressive—not just functional code in a folder.

## Current architecture

- **Core** — PowerShell command/control layer
- **Worker** — background enforcement
- **Boundary** — Windows session lock at cutoff
- **Cooldown** — waits for an actual Windows sleep cycle before resetting
- **Storage** — persistent local JSON state and event logs
- **Learning** — cutoff history for future usual-time suggestions
- **Voice** — optional local Windows speech recognition worker
- **Dates** — current-date awareness
- **Themes** — automatic presentation layer kept separate from enforcement

## 🎨 Universal Date & Theme System

OnCmd has a built-in theme library in [`src/OnCmd.Themes.ps1`](src/OnCmd.Themes.ps1) and date engine in [`src/OnCmd.Dates.ps1`](src/OnCmd.Dates.ps1).

**Celebrations are opt-in.** OnCmd does not assume that a user celebrates a particular holiday or event. Built-in holiday and seasonal preferences default to disabled, while the birthday feature can be configured once and then repeats yearly.

### Birthday setup

After installation:

```powershell
. "$env:LOCALAPPDATA\OnCmd\repo\src\OnCmd.Dates.ps1"
Set-OnCmdBirthday -Month 4 -Day 21
```

The birthday is stored as month/day only—no birth year is required. Run `Set-OnCmdBirthday` again if it changes, or:

```powershell
Clear-OnCmdBirthday
```

### Event preferences

See the current settings:

```powershell
Get-OnCmdEventPreferences
```

Enable an event you actually want OnCmd to recognize:

```powershell
Set-OnCmdEventPreference -Name Halloween -Enabled $true
```

Disable it again:

```powershell
Set-OnCmdEventPreference -Name Halloween -Enabled $false
```

### Custom events

Users can add their own dates instead of relying on OnCmd's built-in assumptions:

```powershell
Add-OnCmdCustomEvent -Name "My Event" -Month 8 -Day 20 -Theme "BIRTHDAY"
```

Remove one with:

```powershell
Remove-OnCmdCustomEvent -Name "My Event"
```

Themes only affect presentation. They **cannot change the cutoff, worker, lock, cooldown, or sleep-reset behavior**.

## Repository layout

```text
OnCmd/
├── README.md
├── LICENSE
├── Install-OnCmd.ps1
├── .gitignore
├── assets/
│   └── oncmd-art.svg
├── src/
│   ├── OnCmd.Dates.ps1
│   └── OnCmd.Themes.ps1
└── config/
    └── config.example.json
```

The repository contains the **program and installer logic**. Runtime state is intentionally kept under `%LOCALAPPDATA%\OnCmd` and is not committed to GitHub.

## Design principles

- Local-first
- Persistent
- Event-driven
- PowerShell-native
- No AI API required for core operation
- Optional local voice control
- Automatic date awareness
- User-controlled celebrations
- Personal birthday theme stored once
- Themes never control the safety/enforcement path
- No credential handling
- No authentication bypass
- No keyboard/mouse interception

## Voice

Voice is optional and disabled by default. When enabled, OnCmd uses Windows `System.Speech` recognition and a Scheduled Task so the listener can run independently of an open PowerShell terminal.

Example commands:

```text
OnCmd, status
OnCmd, what's my usual cutoff?
OnCmd, set my cutoff for 9:15 PM
OnCmd, cancel my schedule
```

Schedule-changing voice commands should require confirmation before being applied.

## Runtime data

OnCmd keeps mutable runtime data outside the repository:

```text
%LOCALAPPDATA%\OnCmd\
├── state.json
├── config.json
├── events.log
├── oncmd.log
└── bin\
```

This keeps personal schedules, history, and machine-specific state out of source control.

## Status

Early development. The project now has the foundation for cutoff enforcement, learning, voice control, date awareness, a universal opt-in theme layer, and a one-command bootstrap installer.
