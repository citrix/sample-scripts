<#
.SYNOPSIS
    Converts Tab Separate Variable Subscription Data into format suitable for Bulk Insert into MS SQL
.DESCRIPTION 
    Used to perform data transformation of exported ESENT subscriptions into a suitable format for import into a SQL database.  
.INPUTS
    Accepts a single <StoreName>.txt Tab Separate Variable file from flat Storefront ESENT database.
.OUTPUTS
    Creates <StoreName>SQL.txt file on the current user's desktop.
.PARAMETER
    StoreName.  This should match the name of your store within StoreFront.
.EXAMPLE
    Transform-SubscriptionDataForStore -StoreName "Store"
.NOTES
    Version 2.  Added string buffer and removed string concatenation to make the script process rows faster.
    File write operation now only happens once at the end after all rows are processed.
    Author: Mark Dear
    Date: 17 Nov, 2020
#>

function Transform-SubscriptionDataForStore
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
        Write-Host "StoreFront export file contains $($TSVObject.Length) rows" -ForegroundColor "Green"

        $StringBuffer = New-Object System.Text.StringBuilder
        [array]$UserSIDs = @()

        # Starts System StopWatch to time the processing of all rows
        Write-Host "Started at $(Get-Date)"
        $StopWatch = [System.Diagnostics.Stopwatch]::StartNew()

        for($row=0; $row -le ($TSVObject.length - 1); $row++)
        {
            [array]$KeyValuePairsXMLStrings = @()
    
            # Split the columns from the StoreFront export file using tabs as the separator
            $LineSplit = $TSVObject[$row].split("`t")
            # Write-Host "Line Contains $($LineSplit.length) data items" -ForegroundColor "Green" 

            # First 4 items are in fixed positions
            $UserSID = $LineSplit[0]
            $UserSIDs += $UserSID

            $DeliveryControllerAppName = $LineSplit[1]
            $AppID = $LineSplit[2] 
            $Status = $LineSplit[3] 
            
            # Process the key value pairs to convert into XML to be written to SQL
            # key = even number
            # value = odd number

            For ($column=4; $column -lt ($LineSplit.length - 1); $column+= 2) 
            {       
                $KeyString = $LineSplit[$column]
                $ValueIndex = ($column + 1)
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
            Write-Host "Processing row $row" -ForegroundColor "Yellow"
            Write-Host "UserSID = $UserSID" -ForegroundColor "Green"
            Write-Host "DeliveryControllerAppName = $DeliveryControllerAppName" -ForegroundColor "Green"
            Write-Host "AppID = $AppID" -ForegroundColor "Green"
            Write-Host "Subscribed Status = $Status" -ForegroundColor "Green"
            Write-Host "SQL App Status = $SQLAppStatus" -ForegroundColor "Green"
            Write-Host "`n"
    
            $Junk = $StringBuffer.Append($UserSID)
            $Junk = $StringBuffer.Append("`t")
            $Junk = $StringBuffer.Append($AppID)
            $Junk = $StringBuffer.Append("`t")
            $Junk = $StringBuffer.Append($DeliveryControllerAppName)
            $Junk = $StringBuffer.Append("`t")
            $Junk = $StringBuffer.Append($SQLAppStatus)
            $Junk = $StringBuffer.Append("`t")
            $Junk = $StringBuffer.Append($MetaData)
            $Junk = $StringBuffer.AppendLine()
        }

        [System.IO.File]::AppendAllText("$env:userprofile\desktop\$StoreName"+"SQL.txt",$StringBuffer.ToString())

        $StopWatch.Stop()
        write-host "Ended at $(Get-Date)"
        write-host "Total Elapsed Time: $($StopWatch.Elapsed.ToString())" 

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