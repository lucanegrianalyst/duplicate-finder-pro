BeforeAll {
    Import-Module "$PSScriptRoot\..\Modules\Engine.psm1" -Force -DisableNameChecking
}

Describe "Test del Motore (Engine)" {
    It "Deve scegliere il file senza (1) come originale" {
        $fintiFile = @(
            [PSCustomObject]@{ Name="canzone (1).mp3"; Length=500; FullName="C:\test\canzone (1).mp3"; LastWriteTime=(Get-Date); CreationTime=(Get-Date) }
            [PSCustomObject]@{ Name="canzone.mp3"; Length=500; FullName="C:\test\canzone.mp3"; LastWriteTime=(Get-Date); CreationTime=(Get-Date) }
        )
        $risultato = Get-BestFile -Files $fintiFile
        $risultato.Name | Should -Be "canzone.mp3"
    }

    It "Deve scegliere il file con dimensione maggiore a parità di nome" {
        $fintiFile = @(
            [PSCustomObject]@{ Name="video.mp4"; Length=100; FullName="C:\test\video.mp4"; LastWriteTime=(Get-Date); CreationTime=(Get-Date) }
            [PSCustomObject]@{ Name="video.mp4"; Length=500; FullName="C:\test2\video.mp4"; LastWriteTime=(Get-Date); CreationTime=(Get-Date) }
        )
        $risultato = Get-BestFile -Files $fintiFile
        $risultato.Length | Should -Be 500
    }

    It "Deve scegliere il file con data di modifica più recente a parità di dimensione" {
        $oggi = Get-Date
        $ieri = (Get-Date).AddDays(-1)
        $fintiFile = @(
            [PSCustomObject]@{ Name="foto.jpg"; Length=100; FullName="C:\test\foto.jpg"; LastWriteTime=$ieri; CreationTime=$ieri }
            [PSCustomObject]@{ Name="foto.jpg"; Length=100; FullName="C:\test2\foto.jpg"; LastWriteTime=$oggi; CreationTime=$oggi }
        )
        $risultato = Get-BestFile -Files $fintiFile
        $risultato.LastWriteTime.ToString("yyyyMMdd") | Should -Be $oggi.ToString("yyyyMMdd")
    }
}
