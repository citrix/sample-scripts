<#
.SYNOPSIS
    Adds StoreFront Server computer accounts to the StoreFrontServers local security group
  
.DESCRIPTION
    Adds Storefront server computer accounts to the StoreFrontServers local security group on the database server.  
    This is necessary to grant storefront servers the ability to read/write to the SQL subscription database.

.PARAMETER SiteID
    The SiteID of the StoreFront deployment and Default Website in IIS. Default = 1

.PARAMETER VirtualPath
    The virtual path to the Store.  For exmaple "/Citrix/Store"

.PARAMETER DBName
    The name of the database you created in MS SQL to hold the Store's subscription data.

.PARAMETER DBServer
    The name of the machine hosting MS SQL Server

.PARAMETER LocalDBServer
    Localhost.  Check this resolves to the correct IPv4 address and not ::1.  

.PARAMETER DBInstance
    The named SQL instance you wish to use to hold StoreFront subscription data. 

.EXAMPLE
    $StoreObject = Get-STFStoreService -SiteID $SiteID -VirtualPath $VirtualPath
    Set-STFStoreSubscriptionsDatabase -StoreService $StoreObject -ConnectionString $ConnectionString

.NOTES
    Author: Mark Dear
    Date: 06 Nov, 2019
#>

$SiteID = 1
$VirtualPath  = "/Citrix/Store"
$DBName = "Store"
$DBServer = "SQL2016Ent"
$DBLocalServer = "localhost"
$DBInstance = "StoreFrontInstance"

# For a remote database instance
$ConnectionString = "Server=$DBServer\$DBInstance;Database=$DBName;Trusted_Connection=True;"
# OR
# For a locally installed database instance
$ConnectionString = "Server=$DBLocalServer\$DBInstance;Database=$DBName;Trusted_Connection=True;"

$StoreObject = Get-STFStoreService -SiteID $SiteID -VirtualPath $VirtualPath

# Sets SQL DB Connection String
Set-STFStoreSubscriptionsDatabase -StoreService $StoreObject -ConnectionString $ConnectionString

# Removes the SQL DB Connection string and reverts back to using ESENT
Set-STFStoreSubscriptionsDatabase -StoreService $StoreObject -UseLocalStorage

# Check the connection string for the Store
Get-STFStoreSubscriptionsDatabase -StoreService $StoreObject