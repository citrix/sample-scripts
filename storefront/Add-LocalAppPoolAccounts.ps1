<#
.SYNOPSIS
    Adds IIS Virtual Accounts to the StoreFrontServers local security group
  
.DESCRIPTION
    Adds IIS Virtual Accounts to the StoreFrontServers local security group.  
    This is necessary to grant StoreFront server App Pools and Services the ability to read/write to the SQL subscription database.

.EXAMPLE

.NOTES
    Author: Mark Dear
    Date: 06 Nov, 2019
#>

# Create Local Group for StoreFront servers on DB Server
$LocalGroupName = "StoreFrontServers"
$Description = "Contains StoreFront Server Machine Accounts or StoreFront AppPool Virtual Accounts"

# Check whether the Local Group Exists
if ([ADSI]::Exists("WinNT://$env:ComputerName/$LocalGroupName"))
{
    Write-Host "$LocalGroupName already exists!" -ForegroundColor "Yellow" 
}
else
{
    Write-Host "Creating $LocalGroupName local security group" -ForegroundColor "Yellow"

    # Create Local User Group
    $Computer = [ADSI]"WinNT://$env:ComputerName,Computer"
    $LocalGroup = $Computer.Create("group",$LocalGroupName)
    $LocalGroup.setinfo()
    $LocalGroup.description = $Description 
    $Localgroup.SetInfo()

    Write-Host "$LocalGroupName local security group created" -ForegroundColor "Green"
}

$Group = [ADSI]"WinNT://$env:ComputerName/$LocalGroupName,group"

# Add IIS APPPOOL\DefaultAppPool
$objAccount = New-Object System.Security.Principal.NTAccount("IIS APPPOOL\DefaultAppPool")
$StrSID = $objAccount.Translate([System.Security.Principal.SecurityIdentifier])
$DefaultSID = $StrSID.Value

$Account = [ADSI]"WinNT://$DefaultSID"
$Group.Add($Account.Path)

# Add IIS APPPOOL\Citrix Receiver for Web
$objAccount = New-Object System.Security.Principal.NTAccount("IIS APPPOOL\Citrix Receiver for Web")
$StrSID = $objAccount.Translate([System.Security.Principal.SecurityIdentifier])
$WebRSID = $StrSID.Value

$Account = [ADSI]"WinNT://$WebRSID"
$Group.Add($Account.Path)

Write-Host "AppPools added to $LocalGroupName local group" -ForegroundColor "Green"