<#
.SYNOPSIS
    Adds StoreFront Server computer accounts to the StoreFrontServers local security group
  
.DESCRIPTION
    Adds Storefront server computer accounts to the StoreFrontServers local security group on the database server.  
    This is necessary to grant storefront servers the ability to read/write to the SQL subscription database.

.PARAMETER Domain
    Name of the domain that the storefront and database servers are joined to.

.PARAMETER StoreFrontServers
    List of StoreFront server AD computer accounts that require access to the subscription database.
    The AD Computer accounts must exist within the domain.

.EXAMPLE
    Add-RemoteSFAccounts.ps1 -Domain "example" -StorefrontServers @("StoreFrontSQL1","StoreFrontSQL2")

.NOTES
    Author: Mark Dear
    Date: 06 Nov, 2019
#>

function Add-RemoteSTFMachineAccounts
{
    [CmdletBinding()]
    param([Parameter(Mandatory=$True)][string]$Domain,
          [Parameter(Mandatory=$True)][array]$StoreFrontServers)

    # Create Local Group for StoreFront servers on DB Server
    $LocalGroupName = "StoreFrontServers"
    $Description = "Contains StoreFront Server Machine Accounts or StoreFront AppPools"

    # Check whether the Local Group Exists
    if ([ADSI]::Exists("WinNT://$env:ComputerName/$LocalGroupName"))
    {
        Write-Host "$LocalGroupName already exists!" -ForegroundColor "Yellow"     
    }
    else
    {
        Write-Host "Creating $LocalGroupName local group" -ForegroundColor "Yellow"
    
        # Create Local User Group
        $Computer = [ADSI]"WinNT://$env:ComputerName,Computer"
        $LocalGroup = $Computer.Create("group",$LocalGroupName)
        $LocalGroup.setinfo()
        $LocalGroup.description = $Description 
        $Localgroup.SetInfo()
    
        Write-Host "$LocalGroupName  local group created" -ForegroundColor "Green"
    }

    Write-Host "Adding $StoreFrontServers to $LocalGroupName local group" -ForegroundColor "Yellow"
    
    foreach ($StoreFrontServer in $StoreFrontServers)
    {
        $Group = [ADSI]"WinNT://$env:ComputerName/$LocalGroupName,group"
        $Computer = [ADSI]"WinNT://$Domain/$StoreFrontServer$"
        $Group.Add($Computer.Path)
    }

    Write-Host "$StoreFrontServers added to $LocalGroupName" -ForegroundColor "Green"

}

Add-RemoteSTFMachineAccounts -Domain "example" -StoreFrontServers @("StoreFrontSQL1","StoreFrontSQL2")