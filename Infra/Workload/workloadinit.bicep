// This Bicep file is used to deploy the initial spoke workload resources.

import * as config from '../config.bicep'

metadata name = 'Bicep - Spoke Networking module'
metadata description = 'This module creates spoke networking resources'

targetScope = 'subscription'

@description('Subscription ID passed in from PowerShell script')
param subscriptionId string

@description('Logged in user details. Passed in from ent "deployNow.ps1" script.')
param updatedBy string = ''

@description('Environment Type: Test, Acceptance/UAT, Production, etc.')
@allowed([
  'dev'
  'prod'
])
param environmentName string = 'dev'

@description('Azure Region to deploy the resources in.')
@allowed([
  'westeurope'
  'uksouth'
])
param location string = 'westeurope'
param locationShortCode string = config.locationShortCodes[location]

param customerName string

@description('Add tags as required as Name:Value')
param tags object = {
  Environment: environmentName
  Customer: customerName
  LastUpdatedOn: utcNow('d')
  LastDeployedBy: updatedBy
  Owner: updatedBy
  Product: ''
  CostCenter: ''
  Deployedby: ''
}

/*
// Resource Group
*/
@description('Array of resource Groups.')
param workloadsResourceGroupArray array = [
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
    name: config.WorkloadAzureSQLResourceGroup(customerName, environmentName, locationShortCode)
    location: location
  }
]

var managedIdentityName = 'id-${customerName}-${environmentName}-${locationShortCode}'

// Azure Key Vault Parameters
var keyVaultName = 'kvlt-${customerName}-${environmentName}-${locationShortCode}'
param kvEnableVaultForDeployment bool = true
param kvEnableVaultForTemplateDeployment bool = true
param kvEnableVaultForDiskEncryption bool = true
param kvEnableSoftDelete bool = false
param kvSoftDeleteRetentionInDays int = 7
param kvEnableRbacAuthorization bool = false
param kvEnablePurgeProtection bool = false
param kvSku string = 'premium'
param kvPublicNetworkAccess string = 'Enabled'

var keyVaultAccessPolicy = [
  {
    objectId: managedIdentity.outputs.principalId //comment out permissions for whats not needed
    permissions: {
      keys: ['get', 'list', 'create', 'delete', 'update', 'import', 'purge', 'recover', 'backup', 'restore', 'encrypt', 'decrypt', 'unwrapKey', 'wrapKey']
      secrets: ['get', 'list', 'set', 'delete', 'purge', 'recover', 'backup', 'restore']
    }
  }
  // {
  //   objectId: '<add your own users object Id here>' /
  //   permissions: {
  //     keys: ['get', 'list', 'create', 'delete', 'update', 'import', 'purge', 'recover', 'backup', 'restore', 'encrypt', 'decrypt', 'unwrapKey', 'wrapKey']
  //     secrets: ['get', 'list', 'set', 'delete', 'purge', 'recover', 'backup', 'restore']
  //   }
  // }
]

@secure()
param kvSqlPoolSecretValue string = 'Xp$%A5*788f:' //TODO: change this to store the secret in KeyVault

@secure()
param kvSQLPassword string = '-()elSd67|8.' //TODO: change this to store the secret in KeyVault


@secure()
param kvVm1SecretValue string = '-(felSd67%8.' //TODO: change this to store the secret in KeyVault

@secure() 
param kvVm2SecretValue string = '-()edGd69£8.' //TODO: change this to store the secret in KeyVault


var logAnalyticsName = 'log-${customerName}-${environmentName}-${locationShortCode}'

// Log Analytics Parameters
param logAnalyticsSkuName string = 'PerGB2018'

@description('Log Analytics Daily Quota in GB. Default: 1GB')
param logAnalyticsDailyQuotaGb int = 1

@description('Number of days data will be retained for.')
param logAnalyticsDataRetention int = 365

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Deployment modules start here. 

//MARK: Resource Groups
@description('Deploy Resource Groups')
module workLoadResourceGroups 'br/public:avm/res/resources/resource-group:0.4.0' = [
  for (resourceGroup, i) in workloadsResourceGroupArray: {
    scope: subscription(subscriptionId)
    name: resourceGroup.name
    params: {
      name: resourceGroup.name
      location: resourceGroup.location
      tags: tags
    }
  }
]

//MARK: ManagedIdentity
@description('Deploy Managed Identity')
module managedIdentity 'br/public:avm/res/managed-identity/user-assigned-identity:0.4.0' = {
  scope: resourceGroup(subscriptionId, workloadsResourceGroupArray[0].name)
  name: 'managedIdentity'
  params: {
    name: managedIdentityName
    location: location
    tags: tags
  }
  dependsOn: [
    workLoadResourceGroups
  ]
}

//MARK: azureLogAnalytics
@description('Deploy Azure Log Analytics')
module logAnalytics 'br/public:avm/res/operational-insights/workspace:0.7.0' = {
  scope: resourceGroup(subscriptionId, workloadsResourceGroupArray[1].name)
  name: 'logAnalytics'
  params: {
    name: logAnalyticsName
    skuName: logAnalyticsSkuName
    location: location
    dailyQuotaGb: logAnalyticsDailyQuotaGb
    dataRetention: logAnalyticsDataRetention
    tags: tags
  }
  dependsOn: [
    workLoadResourceGroups
  ]
}

//MARK: keyVault
@description('Deploy Azure Key Vault')
module keyVault 'br/public:avm/res/key-vault/vault:0.9.0' = {
  scope: resourceGroup(subscriptionId, workloadsResourceGroupArray[0].name)
  name: 'deployKeyVault'
  params: {
    name: keyVaultName
    accessPolicies: keyVaultAccessPolicy
    location: location
    enableVaultForDeployment: kvEnableVaultForDeployment
    enableVaultForTemplateDeployment: kvEnableVaultForTemplateDeployment
    enableVaultForDiskEncryption: kvEnableVaultForDiskEncryption
    enableSoftDelete: kvEnableSoftDelete
    softDeleteRetentionInDays: kvSoftDeleteRetentionInDays
    enableRbacAuthorization: kvEnableRbacAuthorization
    enablePurgeProtection: kvEnablePurgeProtection
    sku: kvSku
    publicNetworkAccess: kvPublicNetworkAccess
    diagnosticSettings: [
      {
        workspaceResourceId: logAnalytics.outputs.resourceId
      }
    ]
    secrets: [
      {
        attributes: {
          enabled: true
        }
        contentType: 'application'
        name: 'kvSecretForSqlPool'
        value: kvSqlPoolSecretValue
      }
      {
        attributes: {
          enabled: true
        }
        contentType: 'application'
        name: 'kvSQLPassword'
        value: kvSQLPassword
      }
      {
        attributes: {
          enabled: true
        }
        contentType: 'application'
        name: 'kvVm1SecretName'
        value: kvVm1SecretValue
      }
      {
        attributes: {
          enabled: true
        }
        contentType: 'application'
        name: 'kvVm2SecretName'
        value: kvVm2SecretValue
      }
    ]
    tags: tags
  }
  dependsOn: [
    workLoadResourceGroups
    logAnalytics
  ]
}

var vmSubnetNsgName = 'nsg-virtualmachinesSubnet'
module vmSubnetNsg 'br/public:avm/res/network/network-security-group:0.5.0' = {
    scope: resourceGroup(subscriptionId, workloadsResourceGroupArray[0].name)
    name: vmSubnetNsgName
    params: {
      name: vmSubnetNsgName
      location: location
      securityRules: [
        // Inbound Rules
        {
          name: 'AllowHttpsInbound'
          properties: {
            access: 'Allow'
            direction: 'Inbound'
            priority: 120
            sourceAddressPrefix: 'Internet'
            destinationAddressPrefix: '*'
            protocol: 'Tcp'
            sourcePortRange: '*'
            destinationPortRange: '443'
          }
        }
        {
          name: 'DenyAllInbound'
          properties: {
            access: 'Deny'
            direction: 'Inbound'
            priority: 4096
            sourceAddressPrefix: '*'
            destinationAddressPrefix: '*'
            protocol: '*'
            sourcePortRange: '*'
            destinationPortRange: '*'
          }
        }
        // Outbound Rules
        {
          name: 'AllowAzureCloudOutbound'
          properties: {
            access: 'Allow'
            direction: 'Outbound'
            priority: 110
            sourceAddressPrefix: '*'
            destinationAddressPrefix: 'AzureCloud'
            protocol: 'Tcp'
            sourcePortRange: '*'
            destinationPortRange: '443'
          }
        }
        {
          name: 'DenyAllOutbound'
          properties: {
            access: 'Deny'
            direction: 'Outbound'
            priority: 4096
            sourceAddressPrefix: '*'
            destinationAddressPrefix: '*'
            protocol: '*'
            sourcePortRange: '*'
            destinationPortRange: '*'
          }
        }
      ]
      tags: tags
    }
    dependsOn: [
      workLoadResourceGroups
    ]
  }
