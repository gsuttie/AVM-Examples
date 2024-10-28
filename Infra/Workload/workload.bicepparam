using './workload.bicep'
import * as config from '../config.bicep'

param subscriptionId = ''
param hubSubscriptionId = ''
param updatedBy = ''
param environmentName = 'dev'
param location = 'westeurope'
param locationShortCode = config.locationShortCodes[location]
param customerName = ''
param tags = {
  Environment: environmentName
  Customer: customerName
  LastDeployedBy: updatedBy
  Owner: updatedBy
  Product: ''
  CostCenter: ''
  Deployedby: ''
}
param workloadsResourceGroupArray = [
  {
    name: config.WorkloadResourceGroup(customerName, environmentName, locationShortCode)
    location: location
  }
  {
    name: config.WorkloadResourceGroupMonitoring(customerName, environmentName, locationShortCode)
    location: location
  }
  {
    name: config.WorkloadWebAppsResourceGroup(customerName, environmentName, locationShortCode)
    location: location
  }
  {
    name: config.WorkloadPrivateEndPointsResourceGroup(customerName, environmentName, locationShortCode)
    location: location
  }
]

param spokeVnetName = 'vnet-${customerName}-spoke-${environmentName}-${locationShortCode}'
param spokeNetworkResoureGroupName = 'rg-${customerName}-spoke-${environmentName}-network-${locationShortCode}'
param hubNetworkResoureGroupName = 'rg-${customerName}-hub-${environmentName}-network-${locationShortCode}'
param networksecurityGroupName = 'nsg-${customerName}-spoke-${environmentName}-${locationShortCode}'
param vmsecurityGroupName = 'nsg-${virtualMachineNSGName}'
param virtualMachineSubnetName = 'virtualmachines'
param virtualMachineNSGName = 'virtualmachinesSubnet'
param storageFileShareAllowBlobPublicAccess = false
param storageFileskuName = 'Standard_LRS'
param logAnalyticsSkuName = 'PerGB2018'
param logAnalyticsDailyQuotaGb = 1
param logAnalyticsDataRetention = 365
param azAppGatewayPip = [
  1
  2
  3
]
param publicIpAddressForAppGatewayName = 'pip-appgw-${customerName}-hub-${environmentName}-${locationShortCode}'
param skuNameAppServicePlanWindows = 'P0v3'
param skuKindAppServicePlanWindows = 'Windows'
param skuCapacityAppServicePlanWindows = 3
param skuKindAppServicePlanLinux = 'Linux'
param appInsightsName = 'appInsightsForWebApps'
param virtualMachinesConfiguration = [
  {
    name: 'vm-1-${customerName}-${environmentName}-${locationShortCode}'
    computerName: 'vm1'
    adminUsername: 'vm1admin'
    keyVaultSecretName: config.kvVm1SecretName
    vmSize: 'Standard_DS1_v2'
    imageReference: {
      publisher: 'Canonical'
      offer: 'ubuntu-24_04-lts'
      sku: 'server'
      version: 'latest'
    }
    osType: 'Linux'
    diskSizeGB: 128
    storageAccountType: 'Premium_LRS'
    loadbalancerBackendPool: []
    backupEnabled: false
  }
  {
    name: 'vm-2-${customerName}-${environmentName}-${locationShortCode}'
    computerName: 'vm2'
    adminUsername: 'vm2admin'
    keyVaultSecretName: config.kvVm2SecretName
    vmSize: 'Standard_DS1_v2'
    imageReference: {
      publisher: 'Canonical'
      offer: 'ubuntu-24_04-lts'
      sku: 'server'
      version: 'latest'
    }
    osType: 'Linux'
    diskSizeGB: 128
    storageAccountType: 'Premium_LRS'
    loadbalancerBackendPool: []
    backupEnabled: false
  }
]
param loadbalancerName = 'lbl2-${customerName}-${environmentName}-${locationShortCode}'
param deployWebApps = false
param deployStorage = false
param deploySQLServer = false

