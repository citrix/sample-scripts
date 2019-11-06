<#
.SYNOPSIS
    Converts TSV Subscription Data into format suitable for Bulk Insert into MS SQL
  
.DESCRIPTION 
    Used to perform data transformation of exported ESENT subscriptions into a suitable format for import into a SQL database.  

.INPUTS
    Accepts a single <StoreName>.txt TSV file from Storefront.

.OUTPUTS
    Creates <StoreName>SQL.txt file on the current user's desktop.

.PARAMETER
    StoreName.  This should match the name of your store in StoreFront.

.EXAMPLE
    Transform-SubscriptionDataForStore -StoreName "Store"

.NOTES
    Author: Mark Dear
    Date: 06 Nov, 2019
#>

function Transform-SubscriptionDataForStore #Tested
{
    [CmdletBinding()]
    param([Parameter(Mandatory=$false)][string]$StoreName)

    $SiteID = 1
    $StoreVirtualPath = "/Citrix/$StoreName"
    
    if(Get-STFStoreService -SiteId $SiteID -VirtualPath $StoreVirtualPath)
    {
        $StoreObject = Get-STFStoreService -SiteId $SiteID -VirtualPath $StoreVirtualPath
        Write-Host "Exporting your Subscriptions Tab Separated File (TSV) for $StoreName" -foreground "Yellow"
        Export-STFStoreSubscriptions -StoreService $StoreObject -FilePath ("$env:userprofile\desktop\$StoreName.txt")

        # Reads in file exported from StoreFront into a Powershell object
        $TSVObject = Get-Content -path ("$env:userprofile\desktop\$StoreName.txt")

        [array]$UserSIDs = @()

        foreach ($Line in $TSVObject)
        {
            [array]$KeyValuePairsXMLStrings = @()
    
            # Debug Code to display raw data coming in
            # $Line | Format-Table -AutoSize
    
            # Split the columns from the StoreFront export file using tabs as the separator
            $LineSplit = $Line.split("`t")
            Write-Host "Line Contains $($LineSplit.length) data items" -ForegroundColor "Green" 

            # First 4 items are in fixed positions
            $UserSID = $LineSplit[0]
            $UserSIDs += $UserSID

            $DeliveryControllerAppName = $LineSplit[1]
            $AppID = $LineSplit[2] 
            $Status = $LineSplit[3] 
            
            For ($i=4; $i -lt ($LineSplit.length - 1); $i+= 2) 
            {       
                $KeyString = $LineSplit[$i]
                $ValueIndex = ($i + 1)
                $ValueString = $LineSplit[$ValueIndex]
                $KeyValuePairXMLString = '<property key="'+$KeyString+'"><value>"'+$ValueString+'"</value></property>'
                $KeyValuePairsXMLStrings += $KeyValuePairXMLString
            }

            $MetaData = '<SubscriptionProperties xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">'+$KeyValuePairsXMLStrings+'</SubscriptionProperties>'

            if ($Status -eq "subscribed")
            {
                $SQLAppStatus = 1   
            }
            else
            {
                $SQLAppStatus = 0
            }
       
            # Debugging Code
            Write-Host "UserSID = $UserSID" -ForegroundColor "Green"
            Write-Host "DeliveryControllerAppName = $DeliveryControllerAppName" -ForegroundColor "Green"
            Write-Host "AppID = $AppID" -ForegroundColor "Green"
            Write-Host "Subscribed Status = $Status" -ForegroundColor "Green"
            Write-Host "SQL App Status = $SQLAppStatus" -ForegroundColor "Green"

            # Process the key value pairs to convert into XML to be written to SQL
            # key = even number
            # value = odd number
    
            Write-Host "XML MetaData = $MetaData" -ForegroundColor "Green"
            Write-Host "`n"
    
            Add-Content -Path ("$env:userprofile\desktop\$StoreName"+"SQL.txt") -Value ($UserSID+"`t"+$AppID+"`t"+$DeliveryControllerAppName+"`t"+$SQLAppStatus+"`t"+$MetaData) -Force
        }

        $UniqueUserSIDS = $UserSIDs | Sort-Object | Select-Object -Unique

        Write-Host "$($UniqueUserSIDS.count) unique UserSIDs found" -ForegroundColor "Green"
        Write-Host "$($TSVObject.count) subscriptions transformed" -ForegroundColor "Green"    
    }
    else
    {
        Write-Host "Store $StoreName does not exist!" -foreground "Red"    
    }
}

Transform-SubscriptionDataForStore -StoreName "Store"