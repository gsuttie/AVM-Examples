using './spoke.bicep'

param hubName = 'demo'
param hubSubscriptionId = '554b4a43-abde-427d-b4b6-b91f82ca2ddb'
param deploySpoke = true
param subscriptionId = ''
param updatedBy = ''
param environmentName = 'dev'
param customerName = ''
param location = 'westeurope'
param locationShortCode = ''
param tags = {
  Environment: environmentName
  Customer: customerName
  LastUpdatedOn: ''
  LastDeployedBy: updatedBy
  Owner: updatedBy
  Product: ''
  CostCenter: ''
  Deployedby: ''
}
param globalResourceLock = 'None'
param spokeResourceGroupArray = [
  {
    name: 'rg-${customerName}-spoke-${environmentName}-network-${locationShortCode}' //1
    location: location
  }
]
param spokeNetworkName = 'vnet-${customerName}-spoke-${environmentName}-${locationShortCode}'
param dnsServerIps = []
param spokeVirtualNetworkLock = 'None'
param ddosProtectionPlanId = ''
param privateDnsZonesEnabled = true
