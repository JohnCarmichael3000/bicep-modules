// function.bicep

// Microsoft Bicep Function Documentation: 
// https://learn.microsoft.com/en-us/azure/templates/microsoft.web/sites?pivots=deployment-language-bicep

/*
Deployment:
  Powershell:
    Install-Module -Name Az -AllowClobber -Force

    # Define parameters
    $resourceGroupName = "myResourceGroup"
    $templateFile = "path\to\your\functionApp.bicep"
    $appSettings = @(
        @{
            name  = "MY_CUSTOM_SETTING"
            value = "customValue"
        },
        @{
            name  = "ANOTHER_SETTING"
            value = "anotherValue"
        }
    )

    # Convert the appSettings array to a JSON string
    $appSettingsJson = $appSettings | ConvertTo-Json -Compress

    # Deploy the Bicep template
    New-AzResourceGroupDeployment `
        -ResourceGroupName $resourceGroupName `
        -TemplateFile $templateFile `
        -appSettings $appSettingsJson

  Azure CLI:
    az deployment group create --resource-group myResourceGroup --template-file functionApp.bicep --parameters appSettings='[
      {"name": "MY_CUSTOM_SETTING", "value": "customValue"},
      {"name": "ANOTHER_SETTING", "value": "anotherValue"} ]'

    az deployment group create --resource-group myResourceGroup --template-file functionApp.bicep --parameters @functionApp.parameters.json

    {
    '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#'
    contentVersion: '1.0.0.0'
    parameters: {
      appSettings: {
        value: [
          {
            name: 'MY_CUSTOM_SETTING'
            value: 'customValue'
          }
          {
            name: 'ANOTHER_SETTING'
            value: 'anotherValue'
          }
        ]
      }
      storageAccountName: {
        value: 'mystorageaccount'
      }
      storageAccountKey: {
        value: 'YOUR_STORAGE_KEY'
      }
      appInsightsInstrumentationKey: {
        value: 'YOUR_INSTRUMENTATION_KEY'
      }
      functionAppName: {
        value: 'myFunctionApp'
      }
      location: {
        value: 'WestUS'
      }
      identityType: {
        value: 'SystemAssigned'
      }
    }
  } 
  
  Check on deployment status from command line: 
    az deployment group list --resource-group rg-resGrpName --output table

  Validate code & view generated json:
  bicep build ./function.bicep

  Key Vault Secret App Setting:
  SettingsGroup__SettingName
  @Microsoft.KeyVault(SecretUri=${keyVaultResource.properties.vaultUri}secrets/GetSecretName/) 
*/

// Len 2-60. Valid characters: Alphanumeric, hyphens and Unicode characters that can be mapped to Punycode. Can't start or end with hyphen.
@minLength(2)
@maxLength(60)
param functionAppName string

@description('The location where the Function App will be deployed. Defaults to the resource group location.')
param location string = resourceGroup().location

@description('An array of key-value pairs for the app settings.')
param appSettings array = [
  {
    name: 'WEBSITE_CONTENTSHARE'
    value: toLower(functionAppName)
  }
  {
    name: 'WEBSITE_RUN_FROM_PACKAGE'
    value: '1'
  }
  {
    name: 'WEBSITE_TIME_ZONE'
    value: 'Pacific Standard Time'
  }
  {
    name: 'FUNCTIONS_EXTENSION_VERSION'
    value: '~4'
  }
  {
    name: 'FUNCTIONS_WORKER_RUNTIME'
    value: 'dotnet-isolated'
  }
  {
    name: 'WEBSITE_USE_PLACEHOLDER_DOTNETISOLATED'
    value: '1'
  }
  {
    name: 'TimerSchedule'
    value: '0 45 7 * * *'
  }
  {
    name: 'Serilog:Using:0'
    value: 'Serilog.Sinks.Console'
  }
  {
    name: 'Serilog:MinimumLevel:Override:Microsoft'
    value: 'Warning'
  }
  {
    name: 'Serilog:MinimumLevel:Override:Worker'
    value: 'Warning'
  }
  {
    name: 'Serilog:MinimumLevel:Override:Host'
    value: 'Warning'
  }
  {
    name: 'Serilog:MinimumLevel:Override:System'
    value: 'Error'
  }
  {
    name: 'Serilog:MinimumLevel:Override:Function'
    value: 'Error'
  }
  {
    name: 'Serilog:MinimumLevel:Override:Azure.Storage.Blobs'
    value: 'Error'
  }
  {
    name: 'Serilog:MinimumLevel:Override:Azure.Core'
    value: 'Error'
  }
  {
    name: 'Serilog:MinimumLevel:Override:Microsoft.Hosting.Lifetime'
    value: 'Information'
  }
  {
    name: 'Serilog:WriteTo:0:Name'
    value: 'Console'
  }
  {
    name: 'Serilog:WriteTo:0:Args:restrictedToMinimumLevel'
    value: 'Information'
  }
]

@description('Specifies whether to deploy the Function App on a Consumption plan or an App Service Plan. Set to true for Consumption plan, false for App Service Plan.')
param useConsumptionPlan bool = true

@description('The resource ID of the App Service Plan. Required if "useConsumptionPlan" is set to false.')
param appServicePlanId string = ''

@description('Specifies the type of managed identity for the Function App. Options are SystemAssigned, UserAssigned, or None.')
@allowed([
  'SystemAssigned'
  'UserAssigned'
  'None'
])
param identityType string = 'None'

@description('The .NET Framework version to use for the Function App.')
param netFrameworkVersion string = 'v8.0'

@description('The managed pipeline mode for the Function App. Options are Integrated or Classic.')
@allowed([
  'Integrated'
  'Classic'
])
param managedPipelineMode string = 'Integrated'

@description('Specifies whether the Function App should use a 32-bit worker process. Defaults to false.')
param use32BitWorkerProcess bool = false

@description('Specifies whether the Function App should always be on. Applicable only for App Service Plan.')
param alwaysOn bool = true

@description('Specifies the FTPS state of the Function App. Options are AllAllowed, FtpsOnly, or Disabled.')
@allowed([
  'AllAllowed'
  'FtpsOnly'
  'Disabled'
])
param ftpsState string = 'Disabled'

@description('Specifies whether client affinity should be enabled for the Function App.')
param clientAffinityEnabled bool = false

@description('Specifies whether HTTPS should be the only allowed protocol for the Function App.')
param httpsOnly bool = true

@description('Specifies a dictionary of tags to be assigned to the Function App.')
param tags object = {}

@description('The Application Insights Instrumentation Key. If not provided, Application Insights will not be configured.')
param appInsightsInstrumentationKey string = ''

@description('The name of the Azure Storage account to be used by the Function App.')
param storageAccountName string

@secure()
@description('The access key of the Azure Storage account to be used by the Function App.')
param storageAccountKey string


resource functionApp 'Microsoft.Web/sites@2022-09-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp'
  identity: {
      type: identityType
  }
  properties: {
    serverFarmId: useConsumptionPlan ? null : appServicePlanId
    siteConfig: {
      netFrameworkVersion: netFrameworkVersion
      managedPipelineMode: managedPipelineMode
      use32BitWorkerProcess: use32BitWorkerProcess
      appSettings: concat(

        // Include existing app settings
        appSettings,

        // Azure function Storage account settings - storage account is required for the function. 
        [
          {
            name: 'AzureWebJobsStorage'
            value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${storageAccountKey};EndpointSuffix=${az.environment().suffixes.storage}'
          }
          {
            name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
            value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${storageAccountKey};EndpointSuffix=${az.environment().suffixes.storage}'
          }
        ],

        // Conditionally add Application Insights settings
        appInsightsInstrumentationKey != '' ? [
          {
            name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
            value: appInsightsInstrumentationKey
          }
          {
            name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
            value: 'InstrumentationKey=${appInsightsInstrumentationKey};IngestionEndpoint=https://${location}-1.in.applicationinsights.azure.com/;LiveEndpoint=https://${location}.livediagnostics.monitor.azure.com/'
          }
        ] : []
      )
      alwaysOn: useConsumptionPlan ? null : alwaysOn
      ftpsState: ftpsState
    }
    clientAffinityEnabled: clientAffinityEnabled
    httpsOnly: httpsOnly
  } 
  tags: tags
}
  
output name string = functionApp.name
output id string = functionApp.identity.principalId
