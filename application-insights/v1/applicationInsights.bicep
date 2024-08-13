// applicationInsights.bicep

@description('The name of the Application Insights resource.')
param appInsightsName string

@description('The location where the Application Insights resource should be deployed.')
param location string = resourceGroup().location

@description('Specifies the type of Application Insights resource to create. Defaults to "web".')
param kind string = 'web'

@description('A set of tags to assign to the Application Insights resource.')
param tags object = {}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: kind
  properties: {
    Application_Type: 'web'
  }
  tags: tags
}

output appInsightsName string = appInsights.name
output appInsightsConnectionString string = appInsights.properties.ConnectionString
output appInsightsInstrumentationKey string = appInsights.properties.InstrumentationKey
