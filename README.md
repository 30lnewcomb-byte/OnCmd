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

**Local-first digital boundary agent with a PowerShell-first architecture and a cross-platform foundation.**

OnCmd started as a Windows PowerShell project built around a simple idea: enforce a user-defined digital cutoff without depending on a cloud service. The architecture is now being expanded so the same core concepts can operate across **Windows, macOS, and Linux**.

## 🚀 One-command setup

You do **not** need to manually create a pile of folders or copy scripts around.

### Windows

On a Windows machine with **Git for Windows** installed, open PowerShell and run:

```powershell
irm https://raw.githubusercontent.com/30lnewcomb-byte/OnCmd/main/Install-OnCmd.ps1 | iex
```

### macOS / Linux

Open Terminal and run:

```bash
curl -fsSL https://raw.githubusercontent.com/30lnewcomb-byte/OnCmd/main/Install-OnCmd.sh | bash
```

The bootstrap installers create the local installation structure, clone or update the repository, verify required files, and create a user-level launcher. They do not silently enable enforcement or voice on a fresh installation.

> **Platform note:** Windows remains the reference implementation for the existing cutoff/sleep enforcement worker. macOS and Linux now have the shared platform abstraction plus native lock/sleep adapters, forming the foundation for full cross-platform enforcement without duplicating the OnCmd brain.

## 🎨 Project Art

OnCmd has a dedicated colorful terminal-inspired project banner in [`assets/oncmd-art.svg`](assets/oncmd-art.svg). Art is an important part of the project because its creator has a genuine passion for art and enjoys bringing that creative side into technical projects. The goal is for OnCmd to feel both engineered and expressive—not just functional code in a folder.

## 🧠 Cross-platform architecture

The project deliberately separates **what OnCmd decides** from **how the operating system performs the action**.

```text
                         ONCMD CORE
                             │
        ┌────────────────────┼────────────────────┐
        │                    │                    │
     Cutoff              Learning              Dates
     Logic               History               Themes
        │                    │                    │
        └────────────────────┼────────────────────┘
                             │
                    PLATFORM ABSTRACTION
                             │
          ┌──────────────────┼──────────────────┐
          │                  │                  │
       Windows            macOS              Linux
      PowerShell          Native             Native
      session lock       osascript           loginctl
      power worker         pmset             systemctl
```

The shared platform layer lives in [`src/OnCmd.Platform.ps1`](src/OnCmd.Platform.ps1).

It provides:

- `Get-OnCmdPlatform`
- `Get-OnCmdPlatformInfo`
- `Invoke-OnCmdLock`
- `Invoke-OnCmdSleep`
- `Test-OnCmdPlatformCapabilities`

This means the core can ask for **"lock the session"** or **"request sleep"** without knowing which operating system is underneath it.

### Native adapters

- macOS: [`platform/macos/oncmd-platform.sh`](platform/macos/oncmd-platform.sh)
- Linux: [`platform/linux/oncmd-platform.sh`](platform/linux/oncmd-platform.sh)

The Linux adapter prefers `systemd/logind` and has common desktop locking fallbacks. The macOS adapter uses the native `osascript` session-lock path and `pmset sleepnow` for system sleep.

## Current architecture

- **Core** — PowerShell command/control layer
- **Worker** — background enforcement
- **Boundary** — session lock at cutoff
- **Cooldown** — waits for the appropriate sleep/reset condition
- **Storage** — persistent local JSON state and event logs
- **Learning** — cutoff history for future usual-time suggestions
- **Voice** — optional local voice layer
- **Dates** — current-date awareness
- **Themes** — automatic presentation layer kept separate from enforcement
- **Platform** — Windows/macOS/Linux abstraction for OS-specific operations

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
├── Install-OnCmd.sh
├── .gitignore
├── assets/
│   └── oncmd-art.svg
├── src/
│   ├── OnCmd.Platform.ps1
│   ├── OnCmd.Dates.ps1
│   └── OnCmd.Themes.ps1
├── platform/
│   ├── macos/
│   │   └── oncmd-platform.sh
│   └── linux/
│       └── oncmd-platform.sh
└── config/
    └── config.example.json
```

The repository contains the **program and installer logic**. Runtime state is intentionally kept outside the repository so personal schedules, history, and machine-specific state are not committed to GitHub.

## Design principles

- Local-first
- Persistent
- Event-driven
- PowerShell-first
- Cross-platform architecture
- No AI API required for core operation
- Optional local voice control
- Automatic date awareness
- User-controlled celebrations
- Personal birthday theme stored once
- Themes never control the enforcement path
- Platform code is isolated from decision logic
- No credential handling
- No authentication bypass
- No keyboard/mouse interception

## Voice

Voice is optional. The original Windows voice worker uses local Windows speech recognition and can run independently of an open PowerShell terminal.

The command language is intended to stay platform-neutral:

```text
OnCmd, status
OnCmd, what's my usual cutoff?
OnCmd, set my cutoff for 9:15 PM
OnCmd, cancel my schedule
```

Schedule-changing voice commands should require confirmation before being applied.

## Runtime data

OnCmd keeps mutable runtime data outside the repository. Windows currently uses:

```text
%LOCALAPPDATA%\OnCmd\
├── state.json
├── config.json
├── events.log
├── oncmd.log
└── bin\
```

The cross-platform installers use user-owned application data locations appropriate to the platform rather than committing runtime state to Git.

## Status

**Early development / cross-platform expansion.** Windows is the reference enforcement platform. The shared platform layer and native macOS/Linux adapters are now in place so the same OnCmd architecture can grow across all three major desktop operating systems without turning the project into three unrelated codebases.
