// function.bicep


// ******************************************************************************************************************************
// PARAMETERS:

// Function Name: Length 2-60 characters. Valid characters: Alphanumeric, hyphens and Unicode characters that can be mapped to Punycode. Can't start or end with hyphen.
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

@description('Specifies whether the Function App should always be on. Applicable only for App Service Plan not the consumption plan.')
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


@description('The name of the Azure Storage account to be used by the Function App. If not provided, a new storage account will be created.')
param storageAccountName string = ''

@description('The resource group of the existing storage account. Required if storageAccountName is provided.')
param storageAccountResourceGroup string = resourceGroup().name

@secure()
@description('The access key of the Azure Storage account to be used by the Function App. If not provided, a new storage account will be created.')
param storageAccountKey string = ''


// ******************************************************************************************************************************
// VARIABLES:

// Generate a unique storage account name if not provided
var filteredFunctionAppName = replace(replace(functionAppName, '-', ''), '_', '')
var truncatedFunctionAppName = toLower(take(filteredFunctionAppName, 21))
var generatedStorageAccountName = 'str${truncatedFunctionAppName}'


// ******************************************************************************************************************************
// Storage Account:

// Create a new storage account if storageAccountName is not provided
resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = if (empty(storageAccountName)) {
  name: generatedStorageAccountName
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {}
}

// Reference an existing storage account if storageAccountName is provided
resource existingStorageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' existing = if (!empty(storageAccountName)) {
  name: storageAccountName
  scope: resourceGroup(storageAccountResourceGroup)
}

// Determine the actual storage account name to be used
var actualStorageAccountName = !empty(storageAccountName) ? storageAccountName : generatedStorageAccountName

// Retrieve the storage account key, either from the provided key or by querying the account
var actualStorageAccountKey = !empty(storageAccountKey) ? storageAccountKey : storageAccount.listKeys().keys[0].value


// ******************************************************************************************************************************
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
            value: 'DefaultEndpointsProtocol=https;AccountName=${actualStorageAccountName};AccountKey=${actualStorageAccountKey};EndpointSuffix=${az.environment().suffixes.storage}'
          }
          {
            name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
            value: 'DefaultEndpointsProtocol=https;AccountName=${actualStorageAccountName};AccountKey=${actualStorageAccountKey};EndpointSuffix=${az.environment().suffixes.storage}'
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
    publicNetworkAccess: 'Enabled'
    clientAffinityEnabled: clientAffinityEnabled
    httpsOnly: httpsOnly
  } 
  tags: tags
  dependsOn: [
    storageAccount
  ]  
}
  
output name string = functionApp.name
output id string = functionApp.id
output principalId string = contains(functionApp, 'identity') && contains(functionApp.identity, 'principalId') ? functionApp.identity.principalId : 'Not Available'
output storageAccountNameOutput string = actualStorageAccountName
