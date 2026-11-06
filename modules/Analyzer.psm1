function Find-DuplicatiPerDimensione {
    param([Parameter(Mandatory)][array]$Files)
    $Files | Group-Object -Property Length | Where-Object Count -gt 1 |
        Sort-Object { $_.Group[0].Length } -Descending |
        ForEach-Object {
            [PSCustomObject]@{
                Tipo = "Dimensione"; Chiave = "{0} byte ({1:N2} MB)" -f $_.Group[0].Length, ($_.Group[0].Length / 1MB)
                Conteggio = $_.Count; Dimensione = $_.Group[0].Length; Files = $_.Group.FullName
            }
        }
}
function Find-DuplicatiPerNome {
    param([Parameter(Mandatory)][array]$Files)
    $Files | Group-Object -Property Name | Where-Object Count -gt 1 | Sort-Object Name |
        ForEach-Object {
            [PSCustomObject]@{
                Tipo = "Nome"; Chiave = $_.Name; Conteggio = $_.Count
                Dimensione = $_.Group[0].Length; Files = $_.Group.FullName
            }
        }
}
function Find-DuplicatiPerHash {
    param([Parameter(Mandatory)][array]$Files, [scriptblock]$HashFunction)
    $candidati = $Files | Group-Object Length | Where-Object Count -gt 1 | ForEach-Object { $_.Group }
    $hashMap = @{}
    foreach ($f in $candidati) {
        $h = & $HashFunction $f.FullName
        if (-not $h) { continue }
        $key = "$h|$($f.Length)"
        if (-not $hashMap.ContainsKey($key)) {
            $hashMap[$key] = [PSCustomObject]@{ Dimensione = $f.Length; Files = @() }
        }
        $hashMap[$key].Files += $f.FullName
    }
    $hashMap.GetEnumerator() | Where-Object { $_.Value.Files.Count -gt 1 } |
        Sort-Object { $_.Value.Files.Count } -Descending | ForEach-Object {
            [PSCustomObject]@{
                Tipo = "Hash"; Chiave = (($_.Key -split '\|')[0].Substring(0,16)) + "..."
                Conteggio = $_.Value.Files.Count; Dimensione = $_.Value.Dimensione; Files = $_.Value.Files
            }
        }
}
Export-ModuleMember -Function Find-DuplicatiPerDimensione, Find-DuplicatiPerNome, Find-DuplicatiPerHash
