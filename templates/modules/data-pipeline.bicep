resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: 'myLogAnalyticsWorkspace' // Name of your Log Analytics Workspace
  location: resourceGroup().location // Or a specific Azure region like 'East US'
  properties: {
    sku: {
      name: 'PerGB2018' // Or 'Free', 'Standard', 'Premium', 'CapacityReservation'
    }
    retentionInDays: 30 // Data retention period in days
    // Optional: Add other properties like workspaceCapping, publicNetworkAccess, etc.
  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: 'my-application-insights'
  location: 'westus'
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id
  }
}
