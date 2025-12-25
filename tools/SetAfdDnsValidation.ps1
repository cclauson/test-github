param (
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroup,

    [Parameter(Mandatory=$true)]
    [string]$FrontDoorProfileName,

    [Parameter(Mandatory=$true)]
    [string]$CustomDomainName,

    [Parameter(Mandatory=$true)]
    [string]$DnsZoneName,

    [Parameter(Mandatory=$true)]
    [string]$DnsZoneResourceGroup,

    [Parameter(Mandatory=$true)]
    [string]$Subdomain
)

# Get the AFD custom domain validation token using Azure CLI
Write-Host "Retrieving validation token from Azure Front Door custom domain..."

$customDomainJson = az afd custom-domain show `
    --resource-group $ResourceGroup `
    --profile-name $FrontDoorProfileName `
    --custom-domain-name $CustomDomainName `
    --query "{validationState:domainValidationState, validationToken:validationProperties.validationToken}" `
    -o json

if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to retrieve custom domain information."
    exit 1
}

$customDomain = $customDomainJson | ConvertFrom-Json
$validationToken = $customDomain.validationToken
$validationState = $customDomain.validationState

Write-Host "Current validation state: $validationState"

if ($validationState -eq "Approved") {
    Write-Host "Domain is already validated. No action needed."
    exit 0
}

if (-not $validationToken) {
    Write-Error "Could not retrieve validation token from custom domain."
    exit 1
}

Write-Host "Validation token: $validationToken"

# Create the TXT record name (_dnsauth.subdomain)
$txtRecordName = "_dnsauth.$Subdomain"

Write-Host "Creating/updating TXT record '$txtRecordName' in DNS zone '$DnsZoneName'..."

# Check if TXT record already exists
$existingRecord = az network dns record-set txt show `
    --resource-group $DnsZoneResourceGroup `
    --zone-name $DnsZoneName `
    --name $txtRecordName `
    2>$null

if ($existingRecord) {
    Write-Host "TXT record already exists. Updating..."
    # Delete existing record set and recreate
    az network dns record-set txt delete `
        --resource-group $DnsZoneResourceGroup `
        --zone-name $DnsZoneName `
        --name $txtRecordName `
        --yes
}

Write-Host "Creating TXT record..."
az network dns record-set txt add-record `
    --resource-group $DnsZoneResourceGroup `
    --zone-name $DnsZoneName `
    --record-set-name $txtRecordName `
    --value $validationToken

if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to create TXT record."
    exit 1
}

Write-Host ""
Write-Host "TXT record created/updated successfully."
Write-Host ""
Write-Host "DNS Record Details:"
Write-Host "  Name: $txtRecordName.$DnsZoneName"
Write-Host "  Type: TXT"
Write-Host "  Value: $validationToken"
Write-Host ""
Write-Host "Note: DNS propagation may take a few minutes. Azure Front Door will automatically"
Write-Host "detect the TXT record and validate the domain."
