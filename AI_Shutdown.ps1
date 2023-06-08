function Invoke-Shutdown {
    param(
        [string[]]$Domains,
        [string]$KeePassDbPath,
        [string[]]$SecretNames
    )

    # Load the KeePass module
    $KeePassModule = Import-Module KeePass

    # Retrieve passwords from KeePass
    $Passwords = foreach ($SecretName in $SecretNames) {
        Get-Secret -Name $SecretName -DatabasePath $KeePassDbPath
    }

    # Select servers in domains (excluding domain controllers, read-only domain controllers, and file servers)
    $ExcludedServerNames = @("Domain Controller", "Read Only Domain Controller")
    $Servers = foreach ($Domain in $Domains) {
        Get-ADComputer -Filter {
            Name -like "*fs??" -and Name.Length -ge 5 -and Name.Length -le 7 -and not (Name -like "*fs??") -and not (OperatingSystem -like "*Server*") -and not (OperatingSystem -like "*Windows*")
        } -SearchBase "DC=$Domain,DC=example,DC=com"
    }

    # Shut down selected servers in 5 minutes
    foreach ($Server in $Servers) {
        Invoke-Command -ComputerName $Server.Name -ScriptBlock {
            shutdown.exe /s /t 300
        }
    }

    # Shut down Debian and Redhat family OSs using Salt API call
    $SaltApiUrl = "https://salt-api.example.com"
    $SaltApiToken = $Passwords[0]  # Assuming the first password retrieved is the Salt API token

    $SaltMinions = Invoke-RestMethod -Uri "$SaltApiUrl/minions" -Headers @{
        "Authorization" = "Bearer $SaltApiToken"
    }

    foreach ($Minion in $SaltMinions) {
        Invoke-RestMethod -Uri "$SaltApiUrl/minion/$Minion/shutdown" -Headers @{
            "Authorization" = "Bearer $SaltApiToken"
        }
    }

    # Select file servers excluded from the previous step
    $FileServers = foreach ($Domain in $Domains) {
        Get-ADComputer -Filter {
            Name -like "*fs??" -and Name.Length -ge 5 -and Name.Length -le 7
        } -SearchBase "DC=$Domain,DC=example,DC=com"
    }

    # Shut down selected file servers in 15 minutes
    foreach ($FileServer in $FileServers) {
        Invoke-Command -ComputerName $FileServer.Name -ScriptBlock {
            shutdown.exe /s /t 900
        }
    }

    # Select remaining servers and desktops
    $RemainingServers = foreach ($Domain in $Domains) {
        Get-ADComputer -Filter {
            not (Name -like "*fs??") -and not (OperatingSystem -like "*Server*") -and not (OperatingSystem -like "*Windows*")
        } -SearchBase "DC=$Domain,DC=example,DC=com"
    }

    # Shut down remaining servers and desktops in 30 minutes
    foreach ($RemainingServer in $RemainingServers) {
        Invoke-Command -ComputerName $RemainingServer.Name -ScriptBlock {
            shutdown.exe /s /t 1800
        }
    }
}

Invoke-Shutdown -Domains @("example.com", "example2.com", "example3.com") -K
