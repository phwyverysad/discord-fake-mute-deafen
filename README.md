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

## Manual Install
1. Run `Install.bat` or `install.ps1`.
2. Select your Discord version or click Install All.

## Features
- Fake Mute: Shows mute icon, microphone stays active.
- Fake Deafen: Shows deafen icon, audio and microphone stay active.
- Real hardware cut: Muting your real mic in Discord still mutes properly.
- Minimal bottom-right dot control panel.
- Supports Discord Stable, PTB, and Canary.
- GUI installer with TH and EN language options.
