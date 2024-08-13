// storageAccount.bicep

// Storage account names must be between 3 and 24 characters in length and may contain numbers and lowercase letters only.
@description('The name of the Azure Storage account to be created.')
param storageAccountName string

@description('The Azure location where the Storage account will be deployed.')
param location string = resourceGroup().location

@description('The kind of Storage account. Default is StorageV2.')
param kind string = 'StorageV2'

@description('The SKU name for the Storage account. Default is Standard_LRS.')
param skuName string = 'Standard_LRS'

@description('A set of tags to assign to the Storage account.')
param tags object = {}

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageAccountName
  location: location
  kind: kind
  sku: {
    name: skuName
  }
  properties: {}
  tags: tags
}

output storageAccountName string = storageAccount.name
output storageAccountId string = storageAccount.id
