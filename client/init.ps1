<#
.SYNOPSIS
    Initialize client configuration from Azure resources.

.DESCRIPTION
    Fetches Application Insights connection string and optionally External ID
    auth configuration, then writes to injected_client_config.json.

.PARAMETER ResourceGroup
    The Azure resource group containing Application Insights.

.PARAMETER ExternalIdTenantId
    (Optional) The External ID tenant ID for authentication config.

.PARAMETER SpaAppDisplayName
    (Optional) The display name of the SPA app registration in External ID.

.EXAMPLE
    # Basic usage (App Insights only)
    ./init.ps1 -ResourceGroup MyTestSite3

.EXAMPLE
    # With External ID auth config
    ./init.ps1 -ResourceGroup MyTestSite3 -ExternalIdTenantId "abc-123" -SpaAppDisplayName "My SPA App"
#>
param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroup,

    [Parameter(Mandatory=$false)]
    [string]$ExternalIdTenantId,

    [Parameter(Mandatory=$false)]
    [string]$SpaAppDisplayName
)

# Get App Insights connection string (requires Azure subscription login)
$aiConnectionString = az resource show -g $ResourceGroup -n my-application-insights --resource-type "microsoft.insights/components" --query properties.ConnectionString -o tsv

$config = @{
    appInsightsConnectionString = $aiConnectionString
}

# If External ID parameters provided, fetch auth config
if ($ExternalIdTenantId -and $SpaAppDisplayName) {
    Write-Host "Fetching auth config from External ID tenant..."
    Write-Host "Note: You must be logged into the External ID tenant (az login --tenant $ExternalIdTenantId)"

    $app = az ad app list --filter "displayName eq '$SpaAppDisplayName'" --query "[0]" 2>$null | ConvertFrom-Json

    if ($app) {
        $config.auth = @{
            clientId = $app.appId
            tenantId = $ExternalIdTenantId
            authority = "https://$ExternalIdTenantId.ciamlogin.com"
        }
        Write-Host "Found SPA app: $($app.appId)"
    } else {
        Write-Warning "SPA app registration not found. Auth config will not be included."
    }
}

$configPath = Join-Path $PSScriptRoot "injected_client_config.json"
$configJson = $config | ConvertTo-Json -Depth 10
[System.IO.File]::WriteAllText($configPath, $configJson)

Write-Host "Configuration written to: $configPath"
