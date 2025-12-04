<p align="center">
  <img src="logo.png" alt="Mr.WMI" width="auto" height="200"/><br><br>

  # MR.WMI - Remote WMI Interactive Console

A session-based, red-team oriented WMI command console built for use in **authorized adversary simulations**, **purple team labs**, and **internal operator development**.

This tool enables interactive remote command execution over WMI (Based on Invoke-WmiMethod) with a focus on:

- Per-session artifact control  
- Operator-tagged session tracking  
- PowerShell/CMD switching  
- File upload/download  
- OPSEC-aware behaviors (non-stealth, non-evasive)  
- Realistic transport metadata and telemetry reminders  

---

## ⚠️ Legal & Ethical Disclaimer

This tool is provided **strictly for use in authorized red team operations, lab testing, and security research**.  
**Do not** use on systems you do not own or without **explicit written permission**.  
The author is not responsible for misuse.

> ⚠ Unauthorized use of this tool is illegal and unethical.  
> Treat it like a weapon: with discipline, transparency, and consent.

---

## Features

| Capability                     | Description                                              |
|--------------------------------|----------------------------------------------------------|
| - Interactive shell            | Run remote commands over WMI with live output            |
| - CMD / PowerShell modes       | Toggle execution mode on the fly                         |
| - Upload                       | Send files to target host via admin share                |
| - Download                     | Retrieve files from target host                          |
| - Cleanup mode                 | Remote artifacts are deleted after every command         |
| - Destructive command warnings | Confirms before executing `del`, `rm`, etc.              |
| - Operator tagging             | All logs are tagged with operator and campaign IDs       |
| - Session logging              | All actions are logged to a local file                   |
| - Per-session artifacts        | Remote files are isolated per session folder             |
| - Smart polling                | Dynamic timing for remote output retrieval               |
| - Telemetry reminders          | Shows which logs may be triggered after each command     |

---

##  Usage

```powershell
.\MrWMI.ps1
```

---

## Example Session

```powershell
[*] Operator:     kimd
[*] Campaign:     C2302
[*] Session ID:   5f3e9a2a
[*] Target:       dc01.internal.lab

[kimd][dc01][cmd]> whoami
...
[kimd][dc01][cmd]> mode ps
[*] Switched to PowerShell mode

[kimd][dc01][ps]> Get-LocalUser
...
[kimd][dc01][ps]> upload C:\payload.exe C:\Tools\payload.exe
[+] Uploaded → C:\Tools\payload.exe
```
