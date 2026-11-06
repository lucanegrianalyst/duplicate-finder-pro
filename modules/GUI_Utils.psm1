function Format-Size {
    param([long]$Bytes)
    if ($Bytes -ge 1GB) { return "{0:N2} GB" -f ($Bytes / 1GB) }
    elseif ($Bytes -ge 1MB) { return "{0:N2} MB" -f ($Bytes / 1MB) }
    else { return "{0:N2} KB" -f ($Bytes / 1KB) }
}
Export-ModuleMember -Function Format-Size
