resource stg 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: 'testappstorageacct'
  location: resourceGroup().location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
  }
}
