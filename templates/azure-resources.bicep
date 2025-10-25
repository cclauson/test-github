resource staticWebApp 'Microsoft.Web/staticSites@2022-03-01' = {
  name: 'testappstaticsite'
  location: resourceGroup().location
  sku: {
    name: 'Free'
  }
  properties: {}
}

output staticWebAppUrl string = staticWebApp.properties.defaultHostname
