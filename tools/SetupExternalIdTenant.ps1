<#
.SYNOPSIS
    Bootstrap script to create an External ID tenant and service principal for GitHub Actions.

.DESCRIPTION
    This script must be run by a user (not a service principal) because External ID tenant
    creation requires a delegated user token. It will:
    1. Create a new Microsoft Entra External ID tenant (appears as Azure resource)
    2. Create a service principal in that tenant with Application.ReadWrite.All permission
    3. Output the credentials needed for GitHub Actions secrets

.PARAMETER ResourceGroup
    The Azure resource group to create the tenant resource in.
    The tenant domain and display name are derived from this.

.PARAMETER DisplayName
    (Optional) Display name for the tenant. Defaults to "<ResourceGroup> Customers"

.PARAMETER Location
    (Optional) The Azure region for the tenant. Defaults to "United States"

.PARAMETER CountryCode
    (Optional) Two-letter country code. Defaults to "US"

.EXAMPLE
    ./SetupExternalIdTenant.ps1 -ResourceGroup "MyTestSite3"

.EXAMPLE
    ./SetupExternalIdTenant.ps1 -ResourceGroup "MyTestSite3" -DisplayName "My App Customer Portal"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroup,

    [Parameter(Mandatory=$false)]
    [string]$DisplayName,

    [Parameter(Mandatory=$false)]
    [string]$Location = "United States",

    [Parameter(Mandatory=$false)]
    [string]$CountryCode = "US"
)

# Derive domain prefix from resource group (lowercase, alphanumeric only)
$DomainPrefix = ($ResourceGroup -replace '[^a-zA-Z0-9]', '').ToLower()

# Derive display name if not provided
if (-not $DisplayName) {
    $DisplayName = "$ResourceGroup Customers"
}

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "External ID Tenant Setup Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Verify user is logged in and get subscription
Write-Host "Step 1: Verifying Azure login..." -ForegroundColor Yellow
$account = az account show 2>$null | ConvertFrom-Json
if (-not $account) {
    Write-Host "Please log in to Azure first using 'az login'" -ForegroundColor Red
    exit 1
}
Write-Host "  Logged in as: $($account.user.name)" -ForegroundColor Green

$SubscriptionId = $account.id
Write-Host "  Using subscription: $($account.name) ($SubscriptionId)" -ForegroundColor Green

# Step 2: Register the resource provider if needed
Write-Host ""
Write-Host "Step 2: Checking resource provider registration..." -ForegroundColor Yellow

$providerState = az provider show --namespace Microsoft.AzureActiveDirectory --query "registrationState" -o tsv 2>$null

if ($providerState -ne "Registered") {
    Write-Host "  Registering Microsoft.AzureActiveDirectory provider..."
    az provider register --namespace Microsoft.AzureActiveDirectory

    # Wait for registration
    $maxWait = 60
    $waited = 0
    while ($waited -lt $maxWait) {
        Start-Sleep -Seconds 5
        $waited += 5
        $providerState = az provider show --namespace Microsoft.AzureActiveDirectory --query "registrationState" -o tsv
        Write-Host "    Registration state: $providerState"
        if ($providerState -eq "Registered") {
            break
        }
    }

    if ($providerState -ne "Registered") {
        Write-Error "Failed to register Microsoft.AzureActiveDirectory provider. Please register it manually."
        exit 1
    }
}
Write-Host "  Provider registered: $providerState" -ForegroundColor Green

# Step 3: Create the External ID tenant
Write-Host ""
Write-Host "Step 3: Creating External ID tenant..." -ForegroundColor Yellow
Write-Host "  Display Name: $DisplayName"
Write-Host "  Domain: $DomainPrefix.onmicrosoft.com"
Write-Host "  Location: $Location"
Write-Host "  Resource Group: $ResourceGroup"

$tenantResourceName = $DomainPrefix.ToLower()

# Check if tenant already exists (suppress error if not found)
$existingTenant = $null
try {
    $ErrorActionPreference = "SilentlyContinue"
    $existingTenantJson = az resource show `
        --resource-group $ResourceGroup `
        --resource-type "Microsoft.AzureActiveDirectory/ciamDirectories" `
        --name $tenantResourceName `
        2>$null
    $ErrorActionPreference = "Stop"

    if ($LASTEXITCODE -eq 0 -and $existingTenantJson) {
        $existingTenant = $existingTenantJson | ConvertFrom-Json
    }
} catch {
    $ErrorActionPreference = "Stop"
    # Resource doesn't exist, which is fine
}

if ($existingTenant) {
    Write-Host "  Tenant already exists, skipping creation..." -ForegroundColor Cyan
    $tenantId = $existingTenant.properties.tenantId
} else {
    # Create the tenant using ARM REST API
    $body = @{
        location = $Location
        properties = @{
            createTenantProperties = @{
                displayName = $DisplayName
                countryCode = $CountryCode
            }
        }
        sku = @{
            name = "Standard"
            tier = "A0"
        }
    } | ConvertTo-Json -Depth 10

    $uri = "https://management.azure.com/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.AzureActiveDirectory/ciamDirectories/$($tenantResourceName)?api-version=2023-05-17-preview"

    Write-Host "  Creating tenant (this may take several minutes)..."

    # Write body to temp file to avoid escaping issues
    $tempFile = [System.IO.Path]::GetTempFileName()
    $body | Out-File -FilePath $tempFile -Encoding utf8

    $response = az rest --method PUT --uri $uri --body "@$tempFile" --headers "Content-Type=application/json" 2>&1

    Remove-Item $tempFile -ErrorAction SilentlyContinue

    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to create External ID tenant: $response"
        exit 1
    }

    $tenantResource = $response | ConvertFrom-Json

    # Wait for tenant to be provisioned
    Write-Host "  Waiting for tenant provisioning..." -ForegroundColor Cyan
    $maxAttempts = 60
    $attempt = 0
    $tenantId = $null

    while ($attempt -lt $maxAttempts) {
        Start-Sleep -Seconds 30
        $attempt++
        Write-Host "    Checking status (attempt $attempt of $maxAttempts)..."

        $status = az resource show `
            --resource-group $ResourceGroup `
            --resource-type "Microsoft.AzureActiveDirectory/ciamDirectories" `
            --name $tenantResourceName `
            2>$null | ConvertFrom-Json

        if ($status -and $status.properties.tenantId) {
            $tenantId = $status.properties.tenantId
            Write-Host "  Tenant provisioned successfully!" -ForegroundColor Green
            break
        }
    }

    if (-not $tenantId) {
        Write-Error "Tenant provisioning timed out. Please check the Azure portal."
        exit 1
    }
}

Write-Host "  Tenant ID: $tenantId" -ForegroundColor Green

# Step 4: Log into the new External ID tenant
Write-Host ""
Write-Host "Step 4: Logging into the External ID tenant..." -ForegroundColor Yellow
Write-Host "  You may be prompted to authenticate again for the new tenant."
Write-Host ""

az login --tenant $tenantId --allow-no-subscriptions
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to log into External ID tenant"
    exit 1
}

# Step 5: Create the app registration for GitHub Actions
Write-Host ""
Write-Host "Step 5: Creating service principal for GitHub Actions..." -ForegroundColor Yellow

$appName = "GitHub Actions - External ID Deployment"

# Check if app already exists
$existingApp = az ad app list --display-name $appName --query "[0]" 2>$null | ConvertFrom-Json

if ($existingApp) {
    Write-Host "  App registration already exists, using existing..." -ForegroundColor Cyan
    $appId = $existingApp.appId
    $appObjectId = $existingApp.id
} else {
    # Create the app registration
    $app = az ad app create --display-name $appName | ConvertFrom-Json
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to create app registration"
        exit 1
    }
    $appId = $app.appId
    $appObjectId = $app.id
    Write-Host "  Created app registration: $appId" -ForegroundColor Green
}

# Create service principal if it doesn't exist
$existingSp = $null
try {
    $ErrorActionPreference = "SilentlyContinue"
    $spJson = az ad sp show --id $appId 2>$null
    $ErrorActionPreference = "Stop"
    if ($LASTEXITCODE -eq 0 -and $spJson) {
        $existingSp = $spJson | ConvertFrom-Json
    }
} catch {
    $ErrorActionPreference = "Stop"
}

if (-not $existingSp) {
    Write-Host "  Creating service principal..."
    az ad sp create --id $appId | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to create service principal"
        exit 1
    }
}

# Step 6: Add Application.ReadWrite.All permission (Microsoft Graph)
Write-Host ""
Write-Host "Step 6: Configuring API permissions..." -ForegroundColor Yellow

# Microsoft Graph App ID (constant)
$graphAppId = "00000003-0000-0000-c000-000000000000"
# Application.ReadWrite.All permission ID
$appReadWriteAllId = "1bfefb4e-e0b5-418b-a88f-73c46d2cc8e9"

# Add the permission (suppress warnings)
$ErrorActionPreference = "SilentlyContinue"
az ad app permission add `
    --id $appId `
    --api $graphAppId `
    --api-permissions "$appReadWriteAllId=Role" `
    2>$null
$ErrorActionPreference = "Stop"

Write-Host "  Added Application.ReadWrite.All permission"

# Grant admin consent
Write-Host "  Granting admin consent..."
$ErrorActionPreference = "SilentlyContinue"
az ad app permission admin-consent --id $appId 2>$null
$consentResult = $LASTEXITCODE
$ErrorActionPreference = "Stop"

if ($consentResult -ne 0) {
    Write-Host "  WARNING: Could not grant admin consent automatically." -ForegroundColor Yellow
    Write-Host "  You may need to grant consent manually in the Azure portal." -ForegroundColor Yellow
}

# Step 7: Create a client secret
Write-Host ""
Write-Host "Step 7: Creating client secret..." -ForegroundColor Yellow

$secret = az ad app credential reset `
    --id $appId `
    --display-name "GitHub Actions Secret" `
    --years 2 `
    | ConvertFrom-Json

if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to create client secret"
    exit 1
}

$clientSecret = $secret.password

# Output the results
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Add the following secrets to your GitHub repository:" -ForegroundColor Cyan
Write-Host ""
Write-Host "  EXTERNAL_ID_TENANT_ID:" -ForegroundColor Yellow
Write-Host "    $tenantId"
Write-Host ""
Write-Host "  EXTERNAL_ID_CLIENT_ID:" -ForegroundColor Yellow
Write-Host "    $appId"
Write-Host ""
Write-Host "  EXTERNAL_ID_CLIENT_SECRET:" -ForegroundColor Yellow
Write-Host "    $clientSecret"
Write-Host ""
Write-Host "IMPORTANT: Save these values now! The client secret cannot be retrieved later." -ForegroundColor Red
Write-Host ""

# Switch back to original subscription
Write-Host "Switching back to original subscription..."
az account set --subscription $SubscriptionId 2>$null

Write-Host "Done!" -ForegroundColor Green
