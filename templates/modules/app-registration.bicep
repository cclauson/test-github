// Enable the Microsoft Graph Bicep extension
extension 'br:mcr.microsoft.com/bicep/extensions/microsoftgraph/v1.0:0.1.9-preview'

@description('The display name for the SPA application')
param appDisplayName string

@description('A unique name for the application (used as alternate key)')
param appUniqueName string

@description('The custom domain for the SPA (e.g., testsite.ceclauson.com)')
param customDomain string

@description('Additional redirect URIs for local development')
param additionalRedirectUris array = [
  'http://localhost:3000'
  'http://localhost:3000/auth/callback'
]

// Construct redirect URIs
var productionRedirectUris = [
  'https://${customDomain}'
  'https://${customDomain}/auth/callback'
]

var allRedirectUris = union(productionRedirectUris, additionalRedirectUris)

// Microsoft Graph API well-known IDs
var microsoftGraphAppId = '00000003-0000-0000-c000-000000000000'
var openIdPermissionId = '37f7f235-527c-4136-accd-4a02d197296e'   // openid
var profilePermissionId = '14dad69e-099b-42c9-810b-d002981feec1'  // profile
var emailPermissionId = '64a6cdd6-aab1-4aaf-94b8-3cc8405e90d0'    // email
var offlineAccessPermissionId = '7427e0e9-2fba-42fe-b0c0-848c9e6a8182' // offline_access

// Create the SPA application registration
resource spaApp 'Microsoft.Graph/applications@v1.0' = {
  displayName: appDisplayName
  uniqueName: appUniqueName

  // For External ID tenants, use this audience
  signInAudience: 'AzureADandPersonalMicrosoftAccount'

  // SPA-specific configuration
  spa: {
    redirectUris: allRedirectUris
  }

  // Request delegated permissions for user sign-in
  requiredResourceAccess: [
    {
      resourceAppId: microsoftGraphAppId
      resourceAccess: [
        {
          id: openIdPermissionId
          type: 'Scope'  // Delegated permission
        }
        {
          id: profilePermissionId
          type: 'Scope'
        }
        {
          id: emailPermissionId
          type: 'Scope'
        }
        {
          id: offlineAccessPermissionId
          type: 'Scope'
        }
      ]
    }
  ]

  // Enable public client flows for SPA
  isFallbackPublicClient: true
}

// Create the service principal for the application
resource spaSp 'Microsoft.Graph/servicePrincipals@v1.0' = {
  appId: spaApp.appId
}

// Outputs for use in the client application
output applicationId string = spaApp.appId
output applicationObjectId string = spaApp.id
output servicePrincipalId string = spaSp.id
output tenantId string = tenant().tenantId
