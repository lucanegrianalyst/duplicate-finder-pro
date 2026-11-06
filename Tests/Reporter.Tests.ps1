BeforeAll {
    Import-Module "$PSScriptRoot\..\Modules\Reporter.psm1" -Force -DisableNameChecking
}

Describe "Test del Reporter" {
    BeforeEach {
        $testDir = "C:\cerca doppioni\Test_Temp"
        if (Test-Path $testDir) { Remove-Item $testDir -Recurse -Force }
        New-Item -ItemType Directory -Path $testDir -Force | Out-Null
        "test" | Set-Content "$testDir\file_test.txt"
    }
    AfterEach {
        Remove-Item "C:\cerca doppioni\Test_Temp" -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item "C:\cerca doppioni\output\cestino" -Recurse -Force -ErrorAction SilentlyContinue
    }

    It "Deve spostare un file nel cestino senza errori" {
        $file = Get-Item "C:\cerca doppioni\Test_Temp\file_test.txt"
        $input = @([PSCustomObject]@{ OggettoOriginale = $file })
        
        $res = Invoke-DuplicatiAction -Anteprima $input -Elimina $false -BaseDir "C:\cerca doppioni"
        
        $res.Gestiti | Should -Be 1
        Test-Path "C:\cerca doppioni\Test_Temp\file_test.txt" | Should -Be $false
    }

    It "Deve creare un report CSV" {
        $input = @([PSCustomObject]@{ Tipo="Esatto"; Nome="test.txt"; Dimensione="1 KB"; Percorso="C:\finto\test.txt" })
        $percorsoReport = Save-DuplicatiReport -Anteprima $input -BaseDir "C:\cerca doppioni"
        
        Test-Path $percorsoReport | Should -Be $true
        Remove-Item $percorsoReport -Force
    }
}
