<#
.SYNOPSIS
    Initialize client configuration from Azure resources.

.DESCRIPTION
    Fetches Application Insights connection string and External ID auth
    configuration from Azure, then writes to injected_client_config.json.

    All configuration is derived from the resource group - no additional
    parameters needed.

.PARAMETER ResourceGroup
    The Azure resource group containing the deployed resources.

.PARAMETER SkipAuth
    (Optional) Skip fetching External ID auth configuration.

.EXAMPLE
    ./init.ps1 -ResourceGroup MyTestSite3

.EXAMPLE
    # Skip auth config (App Insights only)
    ./init.ps1 -ResourceGroup MyTestSite3 -SkipAuth
#>
param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroup,

    [Parameter(Mandatory=$false)]
    [switch]$SkipAuth
)

$ErrorActionPreference = "Stop"

# Get App Insights connection string (requires Azure subscription login)
Write-Host "Fetching Application Insights configuration..." -ForegroundColor Cyan
$aiConnectionString = az resource show -g $ResourceGroup -n my-application-insights --resource-type "microsoft.insights/components" --query properties.ConnectionString -o tsv

if (-not $aiConnectionString) {
    Write-Error "Failed to get Application Insights connection string. Make sure you're logged into Azure."
    exit 1
}

$config = @{
    appInsightsConnectionString = $aiConnectionString
}

Write-Host "  App Insights configured" -ForegroundColor Green

# Fetch External ID auth config unless skipped
if (-not $SkipAuth) {
    Write-Host "Fetching External ID configuration..." -ForegroundColor Cyan

    # Derive tenant resource name from resource group (same logic as SetupExternalIdTenant.ps1)
    $tenantResourceName = ($ResourceGroup -replace '[^a-zA-Z0-9]', '').ToLower()

    # Get tenant ID from the ciamDirectories resource
    $tenantId = az resource show `
        --resource-group $ResourceGroup `
        --resource-type "Microsoft.AzureActiveDirectory/ciamDirectories" `
        --name $tenantResourceName `
        --query "properties.tenantId" -o tsv 2>$null

    if ($tenantId) {
        Write-Host "  Found External ID tenant: $tenantId" -ForegroundColor Green

        # Save current subscription context
        $currentAccount = az account show 2>$null | ConvertFrom-Json

        # Login to External ID tenant to query app registrations
        Write-Host "  Logging into External ID tenant..." -ForegroundColor Cyan
        az login --tenant $tenantId --allow-no-subscriptions 2>&1 | Out-Null

        if ($LASTEXITCODE -eq 0) {
            # Query for SPA app registration (use naming convention from workflow)
            $app = az ad app list --query "[0]" 2>$null | ConvertFrom-Json

            if ($app) {
                $config.auth = @{
                    clientId = $app.appId
                    tenantId = $tenantId
                    authority = "https://$tenantResourceName.ciamlogin.com"
                }
                Write-Host "  Found SPA app: $($app.displayName) ($($app.appId))" -ForegroundColor Green
            } else {
                Write-Warning "No app registration found in External ID tenant. Auth will not be configured."
            }

            # Switch back to original subscription
            if ($currentAccount) {
                Write-Host "  Switching back to Azure subscription..." -ForegroundColor Cyan
                az account set --subscription $currentAccount.id 2>$null
            }
        } else {
            Write-Warning "Could not login to External ID tenant. Auth will not be configured."
        }
    } else {
        Write-Host "  No External ID tenant found in resource group (auth will not be configured)" -ForegroundColor Yellow
    }
}

$configPath = Join-Path $PSScriptRoot "injected_client_config.json"
$configJson = $config | ConvertTo-Json -Depth 10
[System.IO.File]::WriteAllText($configPath, $configJson)

Write-Host ""
Write-Host "Configuration written to: $configPath" -ForegroundColor Green
