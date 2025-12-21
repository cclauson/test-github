@description('The location into which the Azure Storage resources should be deployed.')
param location string

@description('The name of the Azure Storage account to create. This must be globally unique.')
param accountName string

@description('The name of the SKU to use when creating the Azure Storage account.')
@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_ZRS'
  'Premium_LRS'
])
param skuName string

@description('The custom domain name to associate with your Front Door endpoint.')
param customDomainName string

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: accountName
  location: location
  kind: 'StorageV2'
  sku: {
    name: skuName
  }
  properties: {
    publicNetworkAccess: 'Enabled'
    allowBlobPublicAccess: true
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    networkAcls: {
      defaultAction: 'Allow'
    }
    customDomain: {
      name: customDomainName
    }
  }

  resource defaultBlobService 'blobServices' existing = {
    name: 'default'
  }
}

output webEndpointHostName string = replace(replace(storageAccount.properties.primaryEndpoints.web, 'https://', ''), '/', '')
output storageResourceId string = storageAccount.id
