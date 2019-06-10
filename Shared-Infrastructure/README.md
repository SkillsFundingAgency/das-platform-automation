# Apprenticeship Service Shared Infrastructure

The templates hosted in this repository facilitate the deployment of the shared infrastructure for the Apprenticeships Service.

The deployment consists of two layers.

### Subscription layer
The subscription layer owns resources that are shared horizontally across an environment and used for management purposes. For example, Log Analytics, Azure Automation, KeyVault, Storage etc.

### Environment layer
The environment layer owns resources that are shared virtually across an environment and are typically used to provide a platform for other indipendant applications. For example; App Service Plans, Virtual Networks, SQL Servers, ServiceBus etc.

## Deployment

### Azure DevOps deployments
This is the primary method used to deploy the infrastructure. Configuration is stored securely either in the build definition or variable groups and versions artefacts are used when deploying.

### Local deployment
To deploy from your local machine run the script below. If matching environment variables are not found, you will be prompted for the values.

**Note**: This deployment method should ***only*** be used for testing purposes.

``` PowerShell
.\Initialize-SharedInfrastructureDeployment.ps1
```

If you want to set environment variables, the names expected can be found in the **metadata** object for each parameter in [subscription.template.json](templates/subscription.json).

For example:

``` Javascript
"resourceEnvironmentName": {
    "type": "string",
    "metadata": {
    "description": "Base environment name. E.g. DEV. PP, PRD, MO. ",
    "environmentVariable": "resourceEnvironmentName"
    }
}
```
