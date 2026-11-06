# 🎵 Duplicate Finder PRO

A powerful GUI tool to find and manage duplicate files on Windows, optimized for music libraries, photo folders, and videos, even across multiple drives.

![Version](https://img.shields.io/badge/version-11.0-blue.svg)
![Platform](https://img.shields.io/badge/platform-Windows-lightgrey.svg)
![Language](https://img.shields.io/badge/PowerShell-5.1%2B-blueviolet.svg)

## 📖 Description

**Duplicate Finder PRO** is a desktop application written in PowerShell that leverages the **SHA-256** algorithm to identify byte-for-byte identical files with mathematical precision. 
Unlike other tools, it offers an interactive preview, an intelligent original-file selection system (based on quality, date, and name), and the ability to safely move files to the Recycle Bin.

## ✨ Key Features

- 🔍 **Multi-Drive Scanning**: Analyze multiple folders and drives simultaneously.
- 🎯 **Category Filtering**: Choose which file types to analyze (Audio, Video, Images, Documents).
- 🧠 **Intelligent Original Selection**: The file to keep is chosen based on:
  1. Size (quality)
  2. Modified and Created dates (most recent)
  3. Clean file name (avoids `(1)`, `Copy`, `VID_`, etc.)
- ⚡ **Incremental Scanning**: A local cache prevents re-hashing already analyzed files, making subsequent scans lightning fast.
- ☁️ **Cloud Filter**: Ignores OneDrive or Google Drive placeholders that haven't been downloaded yet.
- 👁️ **Interactive Preview**: Resizable table with color-coding (green = original, red = copy), file icons, and double-click to open files or folders.
- 🛡️ **Safety First**: Moves files to the trash (reversible) by default. Permanent deletion requires double confirmation.
- 📝 **Operation Logs**: Every action is recorded in `output/operations.log`.

## 🚀 How to Use

1. Download the latest release (or compile the `.exe` as explained below).
2. Launch `CercaDoppioniMultiHD.exe`.
3. Select the folder or drive to analyze.
4. Check the file categories you're interested in.
5. Click **START ANALYSIS**.
6. In the preview window, review the found files (you can search or open them) and click **PROCEED**.

## 🛠️ How to Compile

If you want to compile from source:
1. Install the `ps2exe` module: `Install-Module -Name ps2exe -Scope CurrentUser -Force`
2. In the project folder, run:
```powershell
Invoke-PS2EXE -InputFile "C:\cerca doppioni\CercaDoppioni.ps1" -OutputFile "C:\cerca doppioni\CercaDoppioniMultiHD.exe" -NoConsole