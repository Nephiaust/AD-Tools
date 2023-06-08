Function Invoke-WinShutdown {
        param(
        [string]$Domain,
        [pscredential]$Credentials
    )

    $DomainDN = ""
    $DomainSplit = $Domain.Split('.')
    Foreach ($Segment in $DomainSplit) {$DomainDN += "DC=" + $Segment.ToLower() + ","}
    $DomainDN = $DomainDN.Substring(0,$DomainDN.Length-1)
    Remove-Variable ('DomainSplit')

    $ServerList = Get-AdComputer -Filter {OperatingSystem -like "*server*"} -SearchBase $DomainDN

    $Servers = @{
        AllServers = @()
        NonDcFsServers = @()
        FileServers = @()
        DCs = @()
    }

    Foreach ($Server in $ServerList) {$Servers.AllServers += $Server.DNSHostName}

    Foreach ($Server in ($ServerList | Where-Object {$_.Name -like "*DC0?" -or $_.Name -like "*RODC0?"})) {
        $Servers.DCs += $Server.DNSHostName
    }

    Foreach ($Server in ($ServerList | Where-Object {$_.Name -like "*FS0?"})) {
        $Servers.FileServers += $Server.DNSHostName
    }

    $TempExcludeDCs = Compare-Object -ReferenceObject $Servers.AllServers -DifferenceObject $Servers.DCs
    $Servers.NonDcFsServers = (Compare-Object -ReferenceObject ($TempExcludeDCs).InputObject -DifferenceObject $Servers.FileServers).InputObject

    Return $Servers
}
