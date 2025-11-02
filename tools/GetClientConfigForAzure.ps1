param(
    [string]$ResourceGroup
)

$aiConnectionString=az resource show -g $ResourceGroup -n my-application-insights --resource-type "microsoft.insights/components" --query properties.ConnectionString -o tsv
Write-Output @"
{
  "appInsightsConnectionString": "$aiConnectionString"
}
"@