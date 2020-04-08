$trustBaseUrl = "https://trust.citrixworkspacesapi.net"

$nlsBaseUrl = "https://sdwan-location.citrixnetworkapi.net"

$bearer = ""
$customer = ""
$tier1 = ""

function Connect-NLS {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string] $clientId,
        [Parameter(Mandatory=$true)]
        [string] $clientSecret,
        [Parameter(Mandatory=$true)]
        [string] $customer
    )

    $script:bearer = GetBearerToken -clientId $clientId -clientSecret $clientSecret
    $script:customer = $customer
    Write-Host "If you haven't received an error message, you are now successfully authenticated with the Network Location Service."
}

function Get-NLSHealth {
    [CmdletBinding()]
    param (
    )

    return Invoke-RestMethod -Uri "${nlsBaseUrl}/root/location/v1/health" -Method GET
}

function Get-NLSBandwidthTiers {
    [CmdletBinding()]
    param (
    )

    $headers = @{"Authorization"="CWSAuth bearer=${script:bearer}"}
    $resp = Invoke-RestMethod -Uri "${nlsBaseUrl}/${script:customer}/location/v1/bandwidthTiers" -Method GET -Headers $headers
    return $resp.bandwidthTiers
}

function New-NLSSite {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string] $name,
        [Parameter(Mandatory=$true)]
        [string[]] $tags,
        [Parameter(Mandatory=$true)]
        [string[]] $ipv4Ranges,
        [Parameter(Mandatory=$false)]
        [string[]] $ipv6Ranges,
        [Parameter(Mandatory=$true)]
        [string] $latitude,
        [Parameter(Mandatory=$true)]
        [string] $longitude
    )

    $body = @{
        "name" = $name;
        "tags" = $tags;
        "ipv4Ranges" = $ipv4Ranges;
        "ipv6Ranges" = $ipv6Ranges;
        "bandwidthTierId" = GetTier1;
        "geoLocation" = @{
          "latitude" = $latitude;
          "longitude" = $longitude;
        };
      }

    $headers = @{"Authorization"="CWSAuth bearer=${script:bearer}"}
    $resp = Invoke-RestMethod -Uri "${nlsBaseUrl}/${script:customer}/location/v1/sites" -Method POST -Body (ConvertTo-Json $body) -Headers $headers
    $siteId = $resp.siteId

    return (Invoke-RestMethod -Uri "${nlsBaseUrl}/${script:customer}/location/v1/sites/${siteId}" -Method GET -Headers $headers).site
}

function Get-NLSSite {
    [CmdletBinding()]
    param (
    )
    
    $headers = @{"Authorization"="CWSAuth bearer=${script:bearer}"}
    $resp = Invoke-RestMethod -Uri "${nlsBaseUrl}/${script:customer}/location/v1/sites" -Method GET -Headers $headers
    foreach ($site in $resp.sites) { 
        Write-Output $site
    }
}

function Set-NLSSite {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $id,
        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $name,
        [Parameter(ValueFromPipelineByPropertyName)]
        [string[]] $tags,
        [Parameter(ValueFromPipelineByPropertyName)]
        [string[]] $ipv4Ranges,
        [Parameter(ValueFromPipelineByPropertyName)]
        [string[]] $ipv6Ranges,
        [Parameter(ValueFromPipelineByPropertyName)]
        $geoLocation
    )

    Process {
        $body = @{
            "name" = $name;
            "tags" = $tags;
            "ipv4Ranges" = $ipv4Ranges;
            "ipv6Ranges" = $ipv6Ranges;
            "bandwidthTierId" = GetTier1;
            "geoLocation" = @{
                "latitude" = $geoLocation.latitude;
                "longitude" = $geoLocation.longitude;
            };
        }

        $headers = @{"Authorization"="CWSAuth bearer=${script:bearer}"}
        Write-Output (Invoke-RestMethod -Uri "${nlsBaseUrl}/${script:customer}/location/v1/sites" -Method POST -Body (ConvertTo-Json $body) -Headers $headers).site
    }
}

function Remove-NLSSite {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $id
    )

    Process {
        $headers = @{"Authorization"="CWSAuth bearer=${script:bearer}"}
        Invoke-RestMethod -Uri "${nlsBaseUrl}/${script:customer}/location/v1/sites/${id}" -Method DELETE -Headers $headers
    }
}

function GetBearerToken {
  param (
    [Parameter(Mandatory=$true)]
    [string] $clientId,
    [Parameter(Mandatory=$true)]
    [string] $clientSecret
  )

  $postHeaders = @{"Content-Type"="application/json"}
  $body = @{
    "ClientId"=$clientId;
    "ClientSecret"=$clientSecret
  }

  $trustUrl = "${trustBaseUrl}/root/tokens/clients"

  $response = Invoke-RestMethod -Uri $trustUrl -Method POST -Body (ConvertTo-Json $body) -Headers $postHeaders

  $bearerToken = $response.token

  return $bearerToken;
}

# Temporary until API change
function GetTier1() {
    if ($script:tier1 -eq "") {
        $script:tier1 = (Get-NLSBandwidthTiers | Where-Object name -EQ "tier1").id
    }

    return $script:tier1
}

Export-ModuleMember -Function 'Connect-*'
Export-ModuleMember -Function 'Get-*'
Export-ModuleMember -Function 'Set-*'
Export-ModuleMember -Function 'New-*'
Export-ModuleMember -Function 'Remove-*'
