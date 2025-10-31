param (
    [string]$IndexDocument,
    [string]$ErrorDocument404Path,
    [string]$storageAccountName,
    [string]$TenantId,
    [string]$ClientId,
    [string]$ClientSecret
)

Connect-AzAccount -ServicePrincipal -Tenant $TenantId -Credential (New-Object System.Management.Automation.PSCredential($ClientId, (ConvertTo-SecureString $ClientSecret -AsPlainText -Force))) -ErrorAction Stop
Import-Module Az.Storage
$ctx = New-AzStorageContext -StorageAccountName $storageAccountName -ErrorAction Stop
Enable-AzStorageStaticWebsite -Context $ctx -IndexDocument $IndexDocument -ErrorDocument404Path $ErrorDocument404Path
