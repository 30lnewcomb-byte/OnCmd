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

## 🎨 Automatic Theme System

OnCmd now has a complete built-in theme library in [`src/OnCmd.Themes.ps1`](src/OnCmd.Themes.ps1). The date engine in [`src/OnCmd.Dates.ps1`](src/OnCmd.Dates.ps1) automatically chooses the theme.

### Built-in themes

| Theme | Automatic trigger |
|---|---|
| 🎂 **Birthday** | Configured birthday; highest priority |
| 🎃 **Halloween** | October 31 |
| 🦃 **Thanksgiving** | Fourth Thursday of November |
| 🎄 **Christmas** | December 20–31 |
| 🎆 **New Year** | January 1 |
| ❤️ **Valentine** | February 14 |
| 🇺🇸 **Independence Day** | July 4 |
| 🎒 **Back to School** | August 15–September 7 |
| 🌸 **Spring** | March–May |
| ☀️ **Summer** | June–August |
| 🍂 **Autumn** | September–November |
| ❄️ **Winter** | December–February |
| ⏻ **Default** | Fallback |

The priority order is deterministic: **Birthday → fixed holidays → Thanksgiving → back-to-school → seasons**.

Themes only affect presentation. They **cannot change the cutoff, worker, lock, cooldown, or sleep-reset behavior**.

### Birthday setup

Set it once:

```powershell
. "$env:LOCALAPPDATA\OnCmd\src\OnCmd.Dates.ps1"
Set-OnCmdBirthday -Month 4 -Day 21
```

The birthday is stored as month/day only, so it automatically works every year. Run `Set-OnCmdBirthday` again if it ever needs to change, or `Clear-OnCmdBirthday` to remove it.

## Repository layout

```text
OnCmd/
├── README.md
├── LICENSE
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
- Automatic theme selection
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

Early development. The project now has the foundation for cutoff enforcement, learning, voice control, date awareness, and a complete automatic theme layer.
