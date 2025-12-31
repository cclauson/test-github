param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroup,

    [Parameter(Mandatory=$false)]
    [string]$ExternalIdTenantId,

    [Parameter(Mandatory=$false)]
    [string]$SpaAppUniqueName
)

# Get Application Insights connection string
$aiConnectionString = az resource show -g $ResourceGroup -n my-application-insights --resource-type "microsoft.insights/components" --query properties.ConnectionString -o tsv

# Build config object
$config = @{
    appInsightsConnectionString = $aiConnectionString
}

# If External ID parameters are provided, fetch auth config
if ($ExternalIdTenantId -and $SpaAppUniqueName) {
    # Query the app registration from External ID tenant
    # Note: Caller must be logged into External ID tenant for this to work
    $app = az ad app list --filter "displayName eq '$SpaAppUniqueName'" --query "[0]" 2>$null | ConvertFrom-Json

    if ($app) {
        $config.auth = @{
            clientId = $app.appId
            tenantId = $ExternalIdTenantId
            authority = "https://$($ExternalIdTenantId.Split('-')[0]).ciamlogin.com/$ExternalIdTenantId"
        }
    }
}

$config | ConvertTo-Json -Depth 10