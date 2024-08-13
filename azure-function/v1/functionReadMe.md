## Azure Functions ReadMe

#### Microsoft Bicep Function Documentation:<br>
https://learn.microsoft.com/en-us/azure/templates/microsoft.web/sites?pivots=deployment-language-bicep

#### Check on deployment status from command line: 
```
az deployment group list --resource-group rg-resGrpName --output table
```

#### Validate bicep code & view the generated json:
```
bicep build ./function.bicep
```

#### Bicep Function Script Deployment:

Powershell:
```PowerShell
Install-Module -Name Az -AllowClobber -Force

# Define parameters
$resourceGroupName = "myResourceGroup"
$templateFile = "path\to\your\functionApp.bicep"

# AppSettings as array
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

# Deploy the Bicep template using "`" for continuing on new line:
New-AzResourceGroupDeployment `
    -ResourceGroupName $resourceGroupName `
    -TemplateFile $templateFile `
    -appSettings $appSettingsJson
```

Azure CLI:

```
az deployment group create --resource-group TestResGrp1 --template-file function.bicep --parameters functionAppName=TestFnc01

az deployment group create --resource-group TestResGrp1 --template-file function.bicep --parameters functionAppName=TestFnc01 storageAccountName=TestStorage01 storageAccountKey=strkey1

az deployment group create --resource-group myResourceGroup --template-file functionApp.bicep --parameters appSettings='[
    {"name": "MY_CUSTOM_SETTING", "value": "customValue"},
    {"name": "ANOTHER_SETTING", "value": "anotherValue"} ]'

# The '@' symbol tells the AZ Cli to use a file reference
az deployment group create --resource-group myResourceGroup --template-file functionApp.bicep --parameters @functionApp.parameters.json
```

#### Sample functionApp.parameters.json:

```json
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
    }
  } 
```
  
#### Key Vault Secret App Setting:
```
SettingsGroup__SettingName
@Microsoft.KeyVault(SecretUri=${keyVaultResource.properties.vaultUri}secrets/GetSecretName/) 
```
