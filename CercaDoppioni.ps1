<#
.SYNOPSIS
    Entry point per Cerca Doppioni PRO.
.DESCRIPTION
    Trova la posizione dell'eseguibile, importa i moduli necessari e avvia la GUI.
.NOTES
    Autore: Luca Negri
    Versione: 7.0
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Trova il percorso esatto dell'eseguibile o dello script
$exePath = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
$baseDir = Split-Path -Parent $exePath

# Fallback nel caso in cui venga eseguito come script .ps1 da console
if (-not $baseDir -or $baseDir -eq "") { 
    $baseDir = "C:\cerca doppioni" 
}

$ModulePath = Join-Path $baseDir "Modules"

# Controllo di sicurezza
if (-not (Test-Path "$ModulePath\GUI.psm1")) {
    [System.Windows.Forms.MessageBox]::Show("Errore: impossibile trovare la cartella Modules.`n`nPercorso cercato:`n$ModulePath")
    exit
}

# Importa i moduli
Import-Module "$ModulePath\GUI.psm1" -Force
Import-Module "$ModulePath\Reporter.psm1" -Force

# Avvia l'interfaccia
Show-MainWindow -BaseDir $baseDir
