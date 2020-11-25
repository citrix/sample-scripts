<#
.SYNOPSIS
    Sets the SQL connection string on the StoreFront Server so that it can read and write subscription data from a remote SQL server instance.  
.DESCRIPTION
    Sets the SQL connection string on the StoreFront Server so that it can read and write subscription data from a remote SQL server instance.
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
.PARAMETER SQLPort
    The custom TCP port that you have set your named SQL instance to use instead of dynamic TCP ports. 
.EXAMPLE
    $StoreObject = Get-STFStoreService -SiteID $SiteID -VirtualPath $VirtualPath
    Set-STFStoreSubscriptionsDatabase -StoreService $StoreObject -ConnectionString $ConnectionString
.NOTES
    Version 2. Added support for custom SQL ports in the connection string that is used to configure the Store.
    Author: Mark Dear
    Date: 17 Nov, 2020
#>

$SiteID = 1
$VirtualPath  = "/Citrix/Store"
$DBName = "Store"
$DBServer = "SQL2016Ent"
$DBLocalServer = "localhost"
$DBInstance = "StoreFrontInstance"
$SQLPort = "2703"

# For a remote database instance use the following:
$ConnectionString = "Server=$DBServer\$DBInstance;Database=$DBName;Trusted_Connection=True;"
# For a remote database instance using a custom SQL TCP port number, use the following,
# taking care to use a comma `,` not a semi colon `;`:
$ConnectionString = "Server=$DBServer\$DBInstance,$SQLPort;Database=$DBName;Trusted_Connection=True;"

# OR

# For a locally installed database instance, use the following:
$ConnectionString = "Server=$DBLocalServer\$DBInstance;Database=$DBName;Trusted_Connection=True;"

$StoreObject = Get-STFStoreService -SiteID $SiteID -VirtualPath $VirtualPath

# Set the SQL DB connection string used by StoreFront to connect to the subscriptions database:
Set-STFStoreSubscriptionsDatabase -StoreService $StoreObject -ConnectionString $ConnectionString

# Removes the SQL DB Connection string and reverts back to using ESENT
Set-STFStoreSubscriptionsDatabase -StoreService $StoreObject -UseLocalStorage

# Check the connection string for the Store
Get-STFStoreSubscriptionsDatabase -StoreService $StoreObject