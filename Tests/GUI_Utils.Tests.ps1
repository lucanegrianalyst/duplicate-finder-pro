BeforeAll {
    Import-Module "$PSScriptRoot\..\Modules\GUI_Utils.psm1" -Force
}

Describe "Test delle Utility" {
    It "Deve formattare correttamente i Byte" {
        Format-Size -Bytes 500 | Should -Be "0,49 KB"
    }
    It "Deve formattare correttamente i Megabyte" {
        Format-Size -Bytes 5242880 | Should -Be "5,00 MB"
    }
    It "Deve formattare correttamente i Gigabyte" {
        Format-Size -Bytes 1073741824 | Should -Be "1,00 GB"
    }
}
