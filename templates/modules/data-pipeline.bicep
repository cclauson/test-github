@description('The location for the resources.')
param location string = resourceGroup().location

@description('The name of the Log Analytics Workspace.')
param logAnalyticsWorkspaceName string

@description('The name of the Application Insights instance.')
param applicationInsightsName string

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: logAnalyticsWorkspaceName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018' // Or 'Free', 'Standard', 'Premium', 'CapacityReservation'
    }
    retentionInDays: 30 // Data retention period in days
    // Optional: Add other properties like workspaceCapping, publicNetworkAccess, etc.
  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: applicationInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id
  }
}
