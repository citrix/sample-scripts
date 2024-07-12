$script:trustBaseUrl = "https://trust.citrixworkspacesapi.net"
$script:nlsBaseUrl = "https://network-location.cloud.com"
function Connect-NLS
{
    <#
        .SYNOPSIS
            Performs the initial authentication handshake to Citrix Cloud. This function must be run prior
            to performing any other actions in this module
        .LINK
            https://docs.citrix.com/en-us/citrix-workspace/workspace-network-location.html#create-a-secure-client
        .EXAMPLE
            $clientId = "XXXX"      #Replace with your clientId
            $clientSecret = "YYY"   #Replace with your clientSecret
            $customer = "CCCCCC"    #Replace with your customerid
            # Connect to Network Location Service
            Connect-NLS -clientId $clientId -clientSecret $clientSecret -customer $customer
        .EXAMPLE
            # Takes credential information via parameter Read-Host
            Connect-NLS
        .NOTES
            The variables required for this function can be found by visiting Citrix Cloud (https://citrix.cloud.com),
            opening the menu at the top left, selecting "Identity and Access Management", followed by opening
            the "API Access" tab
    #>

    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][string]$clientId,
          [Parameter(Mandatory=$true)][string]$clientSecret,
          [Parameter(Mandatory=$true)][string]$customer)

    try
    {
        GetBearerToken -clientId $clientId -clientSecret $clientSecret -ErrorAction Stop
    }
    catch
    {
        Write-Error -Exception $_.Exception -Message "Failed to connect to Citrix Cloud: $($_.ErrorDetails)"
        break
    }

    # When copied directly from Citrix Cloud, there's a potential for a zero-width space to be tacked
    # onto the front. The second trim removes that character.
    $script:customer = $customer.Trim().Trim([char]8203)
    Write-Host "Successfully authenticated to Citrix Cloud!" -ForegroundColor Green
    Write-Host "You may now begin Network Location Sites configuration by using ``New-NLSSite``"
}

function Get-NLSHealth
{
    [CmdletBinding()]
    param()
    Write-Host "${script:nlsBaseUrl}/location/v1/health"
  
    return Invoke-RestMethod -Uri "${script:nlsBaseUrl}/location/v1/health" -Method GET
}

function Get-NLSBandwidthTiers
{

    [CmdletBinding()]
    param()

    $response = Invoke-AuthenticatedRestMethod -Uri "${script:nlsBaseUrl}/location/v1/bandwidthTiers"
    return $response.bandwidthTiers
}

function New-NLSSite
{
    <#
        .SYNOPSIS
            Creates a new physical site location in Citrix Cloud for Network Location Services

        .PARAMETER name
            Site Nickname

        .PARAMETER tags
            List of tags to associate with the site

        .PARAMETER ipv4Ranges
            CIDR IPv4 address list associated with the site

        .PARAMETER ipv6Ranges
            CIDR IPv6 address list associated with the site

        .PARAMETER latitude
            Geographical latitude of the site

        .PARAMETER longitude
            Geographical longitude of the site

        .PARAMETER internal
            Boolean: $True or $False

        .EXAMPLE
            New-NLSSite -name "New York" -tags @("EastCoast") -ipv4Ranges @("999.999.999.999/24") -longitude 40.7128 -latitude -74.0060 -internal $True
    #>

    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][string]$name,
          [Parameter(Mandatory=$true)][string[]]$tags,
          [Parameter(Mandatory=$true)][string[]]$ipv4Ranges,
          [Parameter(Mandatory=$false)][string[]]$ipv6Ranges,
          [Parameter(Mandatory=$true)][string]$latitude,
          [Parameter(Mandatory=$true)][string]$longitude,
          [Parameter(Mandatory=$true)][bool]$internal)

    $body = @{
        "name"            = $name;
        "tags"            = $tags;
        "ipv4Ranges"      = $ipv4Ranges;
        "ipv6Ranges"      = $ipv6Ranges;
        "internal"        = $internal;
        "bandwidthTierId" = GetTier1;
        "geoLocation"     = @{
            "latitude"  = $latitude;
            "longitude" = $longitude;
        };
    }

    $response = Invoke-AuthenticatedRestMethod -Uri "${script:nlsBaseUrl}/location/v1/sites" -Method POST -Body (ConvertTo-Json $body)
    $siteId = $response.siteId
  
    return (Invoke-AuthenticatedRestMethod -Uri "${script:nlsBaseUrl}/location/v1/sites/${siteId}").site
}
  
function Get-NLSSite
{
     
    <#
        .SYNOPSIS
            Retrieves a list of all sites associated with the current Citrix Cloud Customer

        .EXAMPLE
            Get-NLSSite

        .EXAMPLE
            Get-NLSSite | Out-GridView
    #>

    [CmdletBinding()]
    param()

    try
    {
        $(Invoke-AuthenticatedRestMethod -Uri "${script:nlsBaseUrl}/location/v1/sites").sites
    }
    catch
    {
        # NLS returns 404 if no sites have ever been configured. Catch the error and drop it.
        if ([int]$_.Exception.InnerException.Response.StatusCode -ne 404)
        {
            throw
        }
  
        Write-Verbose "Service returned 404 - this typically means no sites have been configured for this customer before. Run ``New-NLSSite`` and try again"
    }
}

function Set-NLSSite
{
    <#
        .SYNOPSIS
            Updates an existing site with new information

        .PARAMETER name
            Site Nickname

        .PARAMETER tags
            List of tags to associate with the site

        .PARAMETER ipv4Ranges
            CIDR IPv4 address list associated with the site

        .PARAMETER ipv6Ranges
            CIDR IPv6 address list associated with the site

        .PARAMETER geoLocation
            Geographical location of the site. Note this is a PSObject, unlike `New-NLSSite`

        .PARAMETER internal
            Boolean: $True or $False

        .EXAMPLE
            Get-NLSSite | Where-Object {$_.id -like "zzz*"} | Set-NlsSite -ipv4ranges @("127.0.0.1/32") -internal $True -confirm
    #>

    [CmdletBinding(SupportsShouldProcess)]
    param([Parameter(ValueFromPipelineByPropertyName)][string]$id,
          [Parameter(ValueFromPipelineByPropertyName)][string]$name,
          [Parameter(ValueFromPipelineByPropertyName)][string[]]$tags,
          [Parameter(ValueFromPipelineByPropertyName)][string[]]$ipv4Ranges,
          [Parameter(ValueFromPipelineByPropertyName)][string[]]$ipv6Ranges,
          [Parameter(ValueFromPipelineByPropertyName)]$geoLocation,
          [Parameter(ValueFromPipelineByPropertyName)][bool]$internal)

    Process {
        $body = @{
            "name"            = $name;
            "tags"            = $tags;
            "ipv4Ranges"      = $ipv4Ranges;
            "ipv6Ranges"      = $ipv6Ranges;
            "internal"        = $internal;
            "bandwidthTierId" = GetTier1;
            "geoLocation"     = @{
                "latitude"  = $geoLocation.latitude;
                "longitude" = $geoLocation.longitude;
            };
        }

        if ($PSCmdlet.ShouldProcess("`n$(ConvertTo-Json(@{ "id" = $id; "site" = $body; }))"))
        {
            $siteId = (Invoke-AuthenticatedRestMethod -Uri "${script:nlsBaseUrl}/location/v1/sites/$id" -Method PUT -Body (ConvertTo-Json $body)).siteId

            return (Invoke-AuthenticatedRestMethod -Uri "${script:nlsBaseUrl}/location/v1/sites/${siteId}").site
        }
    }
}

function Remove-NLSSite
{

    <#
        .SYNOPSIS
            Removes a site from the Network Location Service

        .PARAMETER id
            Site ID as defined by `Get-NLSSite`

        .EXAMPLE
            Get-NLSSite | Where-Object {$_.ipv4ranges -contains "127.0.0.1/32"} | Remove-NLSSite -confirm

        .NOTES
            This command supports ShouldProcess arguments and requests confirmation for every invocation.
            To escape this behavior while using scripts, specify `-confirm:$false`
    #>

    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param([Parameter(ValueFromPipelineByPropertyName)][string]$id)

    Process {
        if ($PSCmdlet.ShouldProcess($id))
        {
            Invoke-AuthenticatedRestMethod -Uri "${script:nlsBaseUrl}/location/v1/sites/${id}" -Method DELETE
        }
    }
}

#################################################################################
# Helper Functions
#################################################################################

function GetBearerToken
{
    param([Parameter(Mandatory=$true)][string]$clientId,
          [Parameter(Mandatory=$true)][string]$clientSecret)

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    $postHeaders = @{
        "Accept"       = "application/json";
        "Content-Type" = "application/json";
    }
    $body = @{
        "ClientId"     = $clientId;
        "ClientSecret" = $clientSecret;
    }

    $trustUrl = "${script:trustBaseUrl}/tokens/clients"
    Write-Host $trustUrl $postHeaders $body

    try
    {
        $response = Invoke-RestMethod -Uri $trustUrl -Method POST -Body (ConvertTo-Json $body) -Headers $postHeaders -SessionVariable script:websession
        $script:websession.Headers.Add("Authorization", "CWSAuth bearer=$($response.token)")
    }
    catch
    {
        $script:websession = $null
        throw $_
    }
}

function Invoke-AuthenticatedRestMethod
{
    <#
        .SYNOPSIS
            'Internal' helper method used to attach neccessary headers to the request
    #>

    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][Uri]$Uri,
          [Parameter()][Microsoft.PowerShell.Commands.WebRequestMethod]$Method = 'GET',
          [Parameter()][String]$Body = $null)

    $postHeaders = @{
        "citrix-customerid" = $script:customer;
    }    
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    if ($null -eq $script:websession)
    {
        Write-Warning "Script does not seem to be authenticated. Run ``Connect-NLS`` before continuing further"
        break
    }

    try
    {
        if ([string]::IsNullOrEmpty($Body))
        {
            Invoke-RestMethod -Uri $Uri -Method $Method -Headers $postHeaders  -WebSession $script:websession -ErrorAction Stop
            return
        }
  
        Invoke-RestMethod -Uri $Uri -Method $Method -Body $Body -Headers $postHeaders  -WebSession $script:websession -ErrorAction Stop
        return
    }
    catch [System.Net.WebException]
    {
        if ($null -eq $_.ErrorDetails.Message -or -not $_.ErrorDetails.Message.StartsWith("{")) {
            # Error occurred which we cannot gather any additional detail from
            throw
        }

        # Perform some data massaging to help extract any error information at hand
        $errorDetails = $_.ErrorDetails.Message | ConvertFrom-Json
        if ($errorDetails.PsObject.Properties.Name -contains "error")
        {
            $errorDetails | Add-Member -NotePropertyName Message -NotePropertyValue $errorDetails.error
        }
  
        if ($errorDetails.PsObject.Properties.Name -contains "detail")
        {
            $errorDetails | Add-Member -NotePropertyName Message -NotePropertyValue $errorDetails.detail
        }

        throw New-Object -TypeName System.Net.WebException("Failed to perform requested action: $($errorDetails.Message) ($($errorDetails.Code))", $_.Exception)
    }
}

# Temporary until API change
function GetTier1
{
    if ([string]::IsNullOrEmpty($script:tier1))
    {
        $script:tier1 = (Get-NLSBandwidthTiers -ErrorAction Stop | Where-Object name -EQ "tier1").id
    }
  
    Write-Verbose "Using Tier ID: $($script:tier1)"
  
    $script:tier1
    return
}

Export-ModuleMember -Function 'Connect-*'
Export-ModuleMember -Function 'Get-*'
Export-ModuleMember -Function 'Set-*'
Export-ModuleMember -Function 'New-*'
Export-ModuleMember -Function 'Remove-*'
