# 🎵 Duplicate Finder PRO

[![Download](https://img.shields.io/badge/Download-Latest%20Release-brightgreen?style=for-the-badge&logo=github)](https://github.com/lucanegrianalyst/duplicate-finder-pro/releases/latest)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)

A powerful GUI tool to find and manage duplicate files on Windows, optimized for music libraries, photo folders, and videos, even across multiple drives.

![Version](https://img.shields.io/badge/version-11.25-blue.svg)
![Platform](https://img.shields.io/badge/platform-Windows-lightgrey.svg)
![Language](https://img.shields.io/badge/PowerShell-5.1%2B-blueviolet.svg)

## 📖 Description

**Duplicate Finder PRO** is a desktop application written in PowerShell that leverages the **MD5** algorithm to identify byte-for-byte identical files with mathematical precision. Unlike other tools, it offers an interactive preview, an intelligent original-file selection system (based on quality, date, and name), and the ability to safely move files to the Recycle Bin.

## ✨ Key Features

- 🔍 **Multi-Drive Scanning**: Analyze multiple folders and drives simultaneously.
- 🎯 **Category Filtering**: Choose which file types to analyze (Audio, Video, Images, Documents).
- 🧠 **Intelligent Original Selection**: The file to keep is chosen based on:
  1. Size (quality)
  2. Modified and Created dates (most recent)
  3. Clean file name (avoids `(1)`, `Copy`, `VID_`, etc.)
- ⚡ **High-Speed Scanning**: Uses Stack Traversal to bypass slow folder scanning and MD5 hashing to read files up to 3x faster than SHA-256.
- ⏱️ **Live Countdown Timer (ETA)**: Watch the estimated time remaining decrease in real-time during the hashing phase.
- 🛑 **Abort Anytime**: Stop a long scan without closing the program.
- 🔄 **Show Last Results**: Accidentally closed the preview? Reopen it instantly without re-scanning.
- 🚀 **Async Preview Loading**: The preview window loads chunks of data dynamically, ensuring the UI never freezes even with 10,000+ files.
- ⚡ **Incremental Scanning**: A local cache prevents re-hashing already analyzed files, making subsequent scans lightning fast.
- ☁️ **Cloud Filter**: Ignores OneDrive or Google Drive placeholders that haven't been downloaded yet.
- 👁️ **Interactive Preview**: Resizable table with color-coding (green = original, red = copy), double-click to open files, and inline Remove buttons for folders.
- 🛡️ **Safety First**: Moves files to the trash (reversible) by default. Permanent deletion requires double confirmation.
- 📝 **Operation Logs**: Every action is recorded in `output/operations.log`.

## 🚀 How to Use

1. Download the latest release (or compile the `.exe` as explained below).
2. Launch `DuplicateFinder.exe`.
3. Select the folder or drive to analyze.
4. Check the file categories you're interested in.
5. Click **START ANALYSIS**.
6. In the preview window, review the found files (you can search or open them) and click **PROCEED WITH SELECTED**.

## 🛠️ How to Compile

If you want to compile from source:
1. Install the `ps2exe` module: `Install-Module -Name ps2exe -Scope CurrentUser -Force`
2. In the project folder, run:
~~~powershell
Invoke-PS2EXE -InputFile "C:\cerca doppioni\DuplicateFinder.ps1" -OutputFile "C:\cerca doppioni\DuplicateFinder.exe" -NoConsole
~~~

## 📁 Project Structure

The project follows a modular architecture (no file exceeds 200 lines) to ensure maintainability and scalability:

~~~text
duplicate-finder/
│
├── DuplicateFinder.ps1        # Entry point script
├── Modules/
│   ├── Engine.psm1            # Scanning, Hashing, and Cache engine
│   ├── GUI_Main.psm1          # Main window
│   ├── GUI_Preview.psm1       # Duplicate preview window
│   ├── GUI_Utils.psm1         # GUI utility functions
│   └── Reporter.psm1          # Report generation and trash management
├── config/
│   └── settings.json          # Extension configuration
└── output/                    # Reports and Logs (ignored by Git)
~~~

## ⚙️ Requirements

- Windows 10 / 11
- PowerShell 5.1 or higher
- `ps2exe` module (only for compilation)

---
*Developed with passion and a lot of PowerShell.*
