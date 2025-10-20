resource stg 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: 'testappstorageacct'
  location: resourceGroup().location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
    allowBlobPublicAccess: true
  }
}

resource inlineScriptResource 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'setStorageStaticWebsiteScript'
  location: resourceGroup().location
  kind: 'AzurePowerShell'
  properties: {
    azPowerShellVersion: '11.0'
    scriptContent: loadTextContent('scripts/setStorageStaticWebsite.ps1')
    arguments: '-storageAccountName ${stg.name} -indexDocument index.html -errorDocument 404.html'
    retentionInterval: 'P1D'
  }
}
