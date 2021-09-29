[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12;

# Your credentials from Citrix Cloud Identity and Access Management
[string]$YourCustomerAPIKey = " "
[string]$YourCustomerSecretKey = " "

# Commercial US, EU or AP-S 
[string]$YourCustomerURL = "https://<yourcustomer>.cloud.com"

# OR
# JP region
# [string]$YourCustomerURL = "https://<yourcustomer>.citrixcloud.jp"
 
# Unpack the .ZIP file containing the PowerShell module to a folder
# Point Import-Module to the same path where the Citrix.Workspace.FallbackConfiguration.psm1 file is
$STFFallbackPath = "$Env:UserProfile\Desktop\Fallback" 

if(Test-Path -Path "$STFFallbackPath\Citrix.Workspace.FallbackConfiguration.psm1")
{
    Write-Host "Importing STF Fallback Powershell Module..." -ForegroundColor "Green"
    Import-Module -Name "$STFFallbackPath\Citrix.Workspace.FallbackConfiguration.psm1" -verbose    
}
else
{
    Write-Host "STF Fallback Powershell Module not found inside $STFFallbackPath" -ForegroundColor "Red"
} 

<# Uncomment lines 29 - 43 if your Citrix Cloud customer is in Japan

# Uses jp-production.json file to configure the $env:CTXSWSPOSHSETTINGS variable
$EnvironmentConfigFile = "jp-production.json" 
if(Test-Path -Path "$STFFallbackPath\$EnvironmentConfigFile")
{
    Write-Host "Setting STF Fallback Environment Variables using $EnvironmentConfigFile..." -ForegroundColor "Green"
    $env:CTXSWSPOSHSETTINGS = "$STFFallbackPath\$EnvironmentConfigFile" 
}
else
{
    Write-Host "Path to $EnvironmentConfigFile config file not found." -ForegroundColor "Red"
}

#>

# Display detailed PowerShell help for the Fallback cmdlets
Get-Help Get-WorkspaceFallbackConfiguration -full
Get-Help Set-WorkspaceFallbackConfiguration -full
Get-Help Remove-WorkspaceFallbackConfiguration -full

# Perform Fallback admin tasks
# Get your existing configuration
Get-WorkspaceFallbackConfiguration -WorkspaceUrl $YourCustomerURL `
                                   -ClientId $YourCustomerAPIKey `
                                   -ClientSecret $YourCustomerAPIKey `
                                   -Verbose
 
# Add a new or overwrite/update the existing fallback config
Set-WorkspaceFallbackConfiguration -WorkspaceUrl $YourCustomerURL `
                                   -ClientId $YourCustomerAPIKey `
                                   -ClientSecret $YourCustomerSecretKey `
                                   -Configuration @{ "ServiceTitle" = "StoreFront EU"; "StoreWebAddress" = "https://storefront-eu.example.com/Citrix/StoreWeb/"}, `
                                   @{ "ServiceTitle" = "StoreFront US"; "StoreWebAddress" = "https://storefront-us.domain.com/Citrix/StoreWeb/" }, `
                                   @{ "ServiceTitle" = "StoreFront APAC"; "StoreWebAddress" = "https://storefront-apac.domain.com/Citrix/StoreWeb/" }
 
# Remove the existing Fallback configuration
Remove-WorkspaceFallbackConfiguration -WorkspaceUrl $YourCustomerURL `
                                      -ClientId $YourCustomerAPIKey `
                                      -ClientSecret $YourCustomerSecretKey `
                                      -Verbose
