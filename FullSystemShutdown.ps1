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

    Compare-Object -ReferenceObject $Servers.AllServers -DifferenceObject $Servers.DCs

    # Select servers in domains (excluding domain controllers, read-only domain controllers, and file servers)
<#    $ExcludedServerNames = @("Domain Controller", "Read Only Domain Controller")
     $Servers = foreach ($Domain in $Domains) {
        Get-ADComputer -Filter {
            OperatingSystem -like "*Server*" -and not ()
            
            Name -like "*fs??" -and Name.Length -ge 5 -and Name.Length -le 7 -and not (Name -like "*fs??") -and not (OperatingSystem -like "*Server*") -and not (OperatingSystem -like "*Windows*")
        } -SearchBase "DC=$Domain,DC=example,DC=com"
    } #>
}
