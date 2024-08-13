## Application Insights ReadMe

#### Microsoft Bicep Application Insights Documentation:<br>
https://learn.microsoft.com/en-us/azure/templates/microsoft.insights/components?pivots=deployment-language-bicep


#### Bicep Application Insights Script Deployment:

Azure CLI:

```
az deployment group create --resource-group jcTestResGrp1 --template-file applicationInsights.bicep --parameters appInsightsName=appInsightsJcTestFnc01
