## Storage Account ReadMe

#### Microsoft Bicep Storage Account Documentation:<br>
https://learn.microsoft.com/en-us/azure/templates/microsoft.storage/storageaccounts?pivots=deployment-language-bicep


#### Bicep Storage Account Script Deployment:

Azure CLI:

```
# Remember storage account names must be between 3 and 24 characters in length and may contain numbers and lowercase letters only.
az deployment group create --resource-group TestResGrp1 --template-file storageAccount.bicep --parameters storageAccountName=strTest001
