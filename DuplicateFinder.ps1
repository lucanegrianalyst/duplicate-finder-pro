[System.Windows.Forms.Application]::EnableVisualStyles()
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$exePath = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
$baseDir = Split-Path -Parent $exePath
if (-not $baseDir -or $baseDir -eq "") { $baseDir = "C:\cerca doppioni" }

$ModulePath = Join-Path $baseDir "Modules"

if (-not (Test-Path "$ModulePath\GUI_Main.psm1")) {
    [System.Windows.Forms.MessageBox]::Show("Error: Cannot find Modules folder.`n`nSearched path:`n$ModulePath")
    exit
}

Import-Module "$ModulePath\Engine.psm1" -Force
Import-Module "$ModulePath\Reporter.psm1" -Force
Import-Module "$ModulePath\GUI_Utils.psm1" -Force
Import-Module "$ModulePath\GUI_Preview.psm1" -Force
Import-Module "$ModulePath\GUI_Main.psm1" -Force

Show-MainWindow -BaseDir $baseDir
