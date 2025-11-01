param (
    [string]$IndexDocument,
    [string]$ErrorDocument404Path,
    [string]$storageAccountName)

Import-Module Az.Storage
$ctx = New-AzStorageContext -StorageAccountName $storageAccountName -ErrorAction Stop
Enable-AzStorageStaticWebsite -Context $ctx -IndexDocument $IndexDocument -ErrorDocument404Path $ErrorDocument404Path
