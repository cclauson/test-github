param clientId string
param tenantId string
@secure()
param clientSecret string
param subscriptionId string

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
    arguments: '-storageAccountName ${stg.name} -indexDocument index.html -errorDocument 404.html -StaticWebsiteState Enabled -ClientId ${clientId} -ClientSecret ${clientSecret} -TenantId ${tenantId} -SubscriptionId ${subscriptionId}'
    retentionInterval: 'P1D'
  }
}

resource profile 'Microsoft.Cdn/profiles@2021-06-01' = {
  name: 'cdnProfile'
  location: resourceGroup().location
  sku: {
    name: 'Standard_Microsoft'
  }
}

resource endpoint 'Microsoft.Cdn/profiles/endpoints@2021-06-01' = {
  parent: profile
  location: resourceGroup().location
  name: 'cdnEndpoint'
  properties: {
    isHttpAllowed: false
    isHttpsAllowed: true
    queryStringCachingBehavior: 'IgnoreQueryString'
    contentTypesToCompress: [
      'text/plain'
      'text/html'
      'text/css'
      'application/x-javascript'
      'text/javascript'
    ]
    isCompressionEnabled: true
    origins: [
      {
        name: 'storageOrigin'
        properties: {
          hostName: inlineScriptResource.properties.outputs.WebEndpoint
        }
      }
    ]
  }
}
