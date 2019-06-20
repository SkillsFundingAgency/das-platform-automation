# Apprenticeship Service Shared Infrastructure

The templates hosted in this repository facilitate the deployment of the shared infrastructure for the Apprenticeships Service.

The deployment consists of two layers.

### Subscription layer
The subscription layer owns resources that are shared horizontally across a subscription and are used for management purposes. For example, Log Analytics, Azure Automation, KeyVault, Storage, Alerting, Dashboards etc.

**Note**: A subscription can contain one or more environments.

### Environment layer
The environment layer owns resources that are shared vertically across an environment and are typically used to provide a platform for other independent applications. For example; App Service Plans, Virtual Networks, SQL Servers, ServiceBus etc.

## External dependencies
There is a third layer that is not deployed by these templates. This is the application layer. Deployment templates for applications within this layer are typically stored with the [application code](https://github.com/SkillsFundingAgency/das-reservations/tree/master/azure) as they will share the same lifecycle. These applications will often depend on infrastructure deployed by templates in this repository.

Both shared and application deployments consume templates from the [platform building blocks](https://github.com/SkillsFundingAgency/das-platform-building-blocks) repository.

## Logical view
The diagram below is a logical representation of the deployment template structure.

![ApprenticeshipsSharedInfrastructure](Shared-Infrastructure\images\ApprenticeshipsSharedInfrastructure.png)

## Deployment

### Azure DevOps deployments
This is the primary method used to deploy the infrastructure. Configuration is stored securely either in the build definition or variable groups and versioned artifacts are used when deploying.

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
