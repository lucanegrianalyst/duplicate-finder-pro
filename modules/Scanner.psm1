function Get-FileAudio {
    param(
        [Parameter(Mandatory)][string]$Cartella,
        [string[]]$Estensioni = @(".mp3")
    )
    if (-not (Test-Path -LiteralPath $Cartella)) {
        throw "Cartella non trovata: $Cartella"
    }
    $filtri = $Estensioni | ForEach-Object { "*$_" }
    Get-ChildItem -LiteralPath $Cartella -Recurse -File -Include $filtri -ErrorAction SilentlyContinue |
        Select-Object FullName, Name, Length, DirectoryName, LastWriteTime
}

function Get-FileHashSafe {
    param([Parameter(Mandatory)][string]$Percorso)
    try {
        (Get-FileHash -LiteralPath $Percorso -Algorithm SHA256 -ErrorAction Stop).Hash
    } catch {
        Write-Warning "Impossibile leggere $Percorso : $_"
        $null
    }
}

Export-ModuleMember -Function Get-FileAudio, Get-FileHashSafe
