<#
.SYNOPSIS
    Entry point per Cerca Doppioni PRO.
#>

# ATTIVA GLI STILI VISIVI DI WINDOWS (Risolve il problema delle spunte invisibili)
[System.Windows.Forms.Application]::EnableVisualStyles()

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$exePath = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
$baseDir = Split-Path -Parent $exePath

if (-not $baseDir -or $baseDir -eq "") { 
    $baseDir = "C:\cerca doppioni" 
}

$ModulePath = Join-Path $baseDir "Modules"

if (-not (Test-Path "$ModulePath\GUI.psm1")) {
    [System.Windows.Forms.MessageBox]::Show("Errore: impossibile trovare la cartella Modules.`n`nPercorso cercato:`n$ModulePath")
    exit
}

Import-Module "$ModulePath\GUI.psm1" -Force
Import-Module "$ModulePath\Reporter.psm1" -Force

Show-MainWindow -BaseDir $baseDir
