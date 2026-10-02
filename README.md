# Discord Fake Mute / Deafen

Spoof voice mute and deafen status in Discord while keeping microphone and audio active.

## Quick Install (PowerShell)

```powershell
irm https://raw.githubusercontent.com/phwyverysad/discord-fake-mute-deafen/main/install.ps1 | iex
```

Windows 7 / 8 / 8.1:
```powershell
[Net.ServicePointManager]::SecurityProtocol = 3072 -bor 768 -bor 192; irm https://raw.githubusercontent.com/phwyverysad/discord-fake-mute-deafen/main/install.ps1 | iex
```

## Features
- Multi-client selection (Discord, PTB, Canary).
- Live execution log viewer in GUI.
- Dark and Light theme toggle.
- Thai and English language switch.
- Automated console hiding.
- Minimal bottom-right dot control panel in Discord.
