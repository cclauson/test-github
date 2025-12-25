# test-github

A React single-page application (SPA) deployed to Azure using Infrastructure as Code (IaC) with Bicep templates and GitHub Actions.

## Architecture

- **Frontend**: React 19 + TypeScript + TailwindCSS
- **Hosting**: Azure Blob Storage (static website)
- **CDN**: Azure Front Door with custom domain and WAF
- **Monitoring**: Application Insights
- **IaC**: Bicep templates
- **CI/CD**: GitHub Actions

## Prerequisites

- [Node.js](https://nodejs.org/) (v16 or higher)
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- [GitHub CLI](https://cli.github.com/) (for managing variables/secrets)
- Azure subscription with appropriate permissions

## Local Development

### First-time Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/cclauson/test-github.git
   cd test-github
   ```

2. Login to Azure CLI:
   ```bash
   az login
   ```

3. Initialize the client configuration (fetches App Insights connection string):
   ```powershell
   cd client
   ./init.ps1 -ResourceGroup <your-resource-group>
   ```

4. Install dependencies:
   ```bash
   npm install
   ```

### Running Locally

```bash
cd client
npm start
```

Opens http://localhost:3000 in your browser. The page will reload on edits.

### Running Tests

```bash
cd client
npm test
```

### Building for Production

```bash
cd client
npm run build
```

Output is written to `client/build/`.

## GitHub Actions Workflows

### Azure Template Deployment

**File**: `.github/workflows/azure-template-deployment.yml`
**Trigger**: Manual (`workflow_dispatch`)

Deploys Azure infrastructure:
- Resource Group
- Storage Account (static website hosting)
- Azure Front Door (CDN + WAF)
- Application Insights
- DNS validation for custom domain

### Azure Client App Deployment

**File**: `.github/workflows/azure-deploy-client-app.yml`
**Trigger**: Manual (`workflow_dispatch`)

Builds and deploys the React app:
- Fetches App Insights config from Azure
- Builds the React app
- Uploads to Azure Blob Storage `$web` container

## Configuration

### GitHub Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `AZURE_RESOURCE_GROUP` | Azure resource group name | `MyTestSite2` |
| `CUSTOM_DOMAIN_NAME` | Custom domain for the site | `testsite.ceclauson.com` |
| `DNS_ZONE_NAME` | Azure DNS zone name | `ceclauson.com` |
| `DNS_ZONE_RESOURCE_GROUP` | Resource group containing DNS zone | `defaultresourcegroup-cus` |

### GitHub Secrets

| Secret | Description |
|--------|-------------|
| `AZURE_DEPLOY_CLIENT_ID` | Service principal client ID |
| `AZURE_DEPLOY_CLIENT_SECRET` | Service principal client secret |
| `AZURE_DEPLOY_SUBSCRIPTION_ID` | Azure subscription ID |
| `AZURE_DEPLOY_TENANT_ID` | Azure AD tenant ID |

### Setting Variables/Secrets

```bash
# Variables
gh variable set AZURE_RESOURCE_GROUP --body "MyResourceGroup"
gh variable set CUSTOM_DOMAIN_NAME --body "mysite.example.com"
gh variable set DNS_ZONE_NAME --body "example.com"
gh variable set DNS_ZONE_RESOURCE_GROUP --body "my-dns-rg"

# Secrets (you'll be prompted for values)
gh secret set AZURE_DEPLOY_CLIENT_ID
gh secret set AZURE_DEPLOY_CLIENT_SECRET
gh secret set AZURE_DEPLOY_SUBSCRIPTION_ID
gh secret set AZURE_DEPLOY_TENANT_ID
```

## Project Structure

```
test-github/
├── .github/
│   ├── actions/              # Custom GitHub Actions
│   │   ├── azure-login/      # Azure authentication
│   │   └── create-unique-names/  # Generate unique resource names
│   └── workflows/            # CI/CD pipelines
├── client/                   # React application
│   ├── src/                  # TypeScript source code
│   ├── public/               # Static assets
│   ├── config/               # Webpack configuration
│   ├── scripts/              # Build scripts
│   └── init.ps1              # Azure config initialization
├── templates/                # Bicep IaC templates
│   ├── azure-resources.bicep # Main template
│   ├── resourceGroup.bicep   # Resource group
│   └── modules/              # Bicep modules
│       ├── storage.bicep     # Storage account
│       ├── front-door.bicep  # Azure Front Door
│       └── data-pipeline.bicep
├── tools/                    # Utility scripts
│   ├── EnableStaticWebHosting.ps1
│   ├── GetClientConfigForAzure.ps1
│   └── SetAfdDnsValidation.ps1
└── static/                   # Static HTML files
```

## Deployment

### Initial Setup (First Time)

1. Configure GitHub secrets and variables (see Configuration section)

2. Deploy Azure infrastructure:
   - Go to Actions → "Azure Template Deployment" → Run workflow

3. Deploy the React app:
   - Go to Actions → "Azure Client App Deployment" → Run workflow

### Custom Domain Setup

The Azure Template Deployment workflow automatically:
1. Configures the custom domain in Azure Front Door
2. Creates DNS TXT record for domain validation

DNS validation may take 5-15 minutes after deployment. Once validated, the site will be accessible at your custom domain.

## Troubleshooting

### Local dev fails with config error

Ensure you're logged into Azure CLI and the resource group exists:
```bash
az login
az group show --name <your-resource-group>
```

### Custom domain not working

Check the AFD validation status:
```bash
az afd custom-domain show \
  --profile-name MyFrontDoor \
  --resource-group <your-resource-group> \
  --custom-domain-name <domain-with-dashes> \
  --query domainValidationState
```

### Workflow fails

Check that all GitHub secrets and variables are configured correctly:
```bash
gh secret list
gh variable list
```
