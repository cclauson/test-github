param (
    [string]$IndexDocument,
    [string]$ErrorDocument404Path,
    [string]$storageAccountName,
)

$ctx = New-AzStorageContext -StorageAccountName $storageAccountName -ErrorAction Stop
Enable-AzStorageStaticWebsite -Context $ctx -IndexDocument $IndexDocument -ErrorDocument404Path $ErrorDocument404Path
