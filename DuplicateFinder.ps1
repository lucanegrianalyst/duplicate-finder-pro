[System.Windows.Forms.Application]::EnableVisualStyles()
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$baseDir = $PSScriptRoot
if (-not $baseDir -or $baseDir -eq "") { $baseDir = "C:\cerca doppioni" }

$dataDir = Join-Path $env:APPDATA "DuplicateFinderPRO"
if (-not (Test-Path $dataDir)) { New-Item -ItemType Directory -Path $dataDir -Force | Out-Null }

$ModulePath = Join-Path $baseDir "Modules"

if (-not (Test-Path "$ModulePath\GUI_Main.psm1")) {
    [System.Windows.Forms.MessageBox]::Show("Errore: impossibile trovare la cartella Modules in $ModulePath")
    exit
}

# Importiamo TUTTI i moduli qui, una volta sola.
Import-Module "$ModulePath\GUI_Utils.psm1" -Force -DisableNameChecking
Import-Module "$ModulePath\GUI_Preview.psm1" -Force -DisableNameChecking
Import-Module "$ModulePath\Reporter.psm1" -Force -DisableNameChecking
Import-Module "$ModulePath\Engine.psm1" -Force -DisableNameChecking
Import-Module "$ModulePath\GUI_Main.psm1" -Force -DisableNameChecking

# Avviamo la GUI passando i due percorsi separati
Show-MainWindow -BaseDir $dataDir -ModulePath $ModulePath
