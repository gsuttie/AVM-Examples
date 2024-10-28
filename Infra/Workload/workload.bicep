// This Bicep file is used to deploy the spoke workload resources.

import * as config from '../config.bicep'

metadata name = 'Bicep - Spoke Networking module'
metadata description = 'This module creates spoke networking resources'

targetScope = 'subscription'

@description('Subscription ID passed in from PowerShell script')
param subscriptionId string

@description('Subscription ID passed in from PowerShell script of the Hub')
param hubSubscriptionId string

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
    name: config.WorkloadPrivateEndPointsResourceGroup(customerName, environmentName, locationShortCode)
    location: location
  }
  {
    name: config.WorkloadAzureSQLResourceGroup(customerName, environmentName, locationShortCode)
    location: location
  }
]

var sqlServerName = 'sql-${customerName}-${environmentName}-${locationShortCode}'

var sqlAdministratorLogin = 'sqladmin'

var managedIdentityName = 'id-${customerName}-${environmentName}-${locationShortCode}'

var keyVaultName = 'kvlt-${customerName}-${environmentName}-${locationShortCode}'

@description('Name for spoke Network.')
param spokeVnetName string = 'vnet-${customerName}-spoke-${environmentName}-${locationShortCode}'

param spokeNetworkResoureGroupName string = 'rg-${customerName}-spoke-${environmentName}-network-${locationShortCode}'

param hubNetworkResoureGroupName string = 'rg-${customerName}-hub-${environmentName}-network-${locationShortCode}'

param networksecurityGroupName string = 'nsg-${customerName}-spoke-${environmentName}-${locationShortCode}'

param vmsecurityGroupName string = 'nsg-${virtualMachineNSGName}'

@description('Name for virtual Machine Subnet.')
param virtualMachineSubnetName string = 'virtualmachines'

@description('Name for virtual Machine Subnet.')
param virtualMachineNSGName string = 'virtualmachinesSubnet'

var logAnalyticsName = 'log-${customerName}-${environmentName}-${locationShortCode}'

// Azure Storage account file share settings
var storageFileShareKind = 'StorageV2'
var storageAccountName = 'st${customerName}${environmentName}${locationShortCode}'
param storageFileShareAllowBlobPublicAccess bool = false
param storageFileskuName string = 'Standard_LRS'

// Log Analytics Parameters
param logAnalyticsSkuName string = 'PerGB2018'

@description('Log Analytics Daily Quota in GB. Default: 1GB')
param logAnalyticsDailyQuotaGb int = 1

@description('Number of days data will be retained for.')
param logAnalyticsDataRetention int = 365

@description('Name of the Public IP Address for the Application Gateway.')
param azAppGatewayPip array = [
  1
  2
  3
]

param publicIpAddressForAppGatewayName string = 'pip-appgw-${customerName}-hub-${environmentName}-${locationShortCode}'

param skuNameAppServicePlanWindows string = 'P0v3'
param skuKindAppServicePlanWindows string = 'Windows'
param skuCapacityAppServicePlanWindows int = 3
param skuKindAppServicePlanLinux string = 'Linux'
param appInsightsName string = 'appInsightsForWebApps'

var HubResourceGroupPrivateDNSZones = 'rg-${customerName}-hub-${environmentName}-private_dns_zones-${locationShortCode}'
var pEndpointSubnetName = 'privateEndpointSubnet'
var hubVnetName = 'vnet-${customerName}-hub-${environmentName}-${locationShortCode}'
var hubRg = 'rg-${customerName}-hub-${environmentName}-network-${locationShortCode}'

resource hubVnet 'Microsoft.Network/virtualNetworks@2023-04-01' existing = {
  scope: resourceGroup(hubRg)
  name: hubVnetName
}

resource privateEndpointSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-01-01' existing = {
  parent: hubVnet
  name: pEndpointSubnetName
}

var azFirewallPoliciesName = 'azfwpolicy-demo-uks'
var rgName = 'rg-demo-hub-dev-network-uks'

var privateLinkServiceName = 'pl-${customerName}-${environmentName}-${locationShortCode}'
var privatelinkSubnetName = 'privatelink'

resource privateLinkSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-01-01' existing = {
  parent: spokeVnet
  name: privatelinkSubnetName
}

param loadbalancerName string = 'lbl2-${customerName}-${environmentName}-${locationShortCode}'
var frontendIPConfigurationsName = 'frontendIPConfig'

var azFirewallName = 'azfw-demo-uks'
var azFirewallPolicyName = 'azfwpolicy-demo-uks'

param deployWebApps bool = false
param deployStorage bool = false
param deploySQLServer bool = false
param deployVMs bool = false


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Deployment modules start here. 

//MARK: Existing Resources
resource rgWorkload 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: workloadsResourceGroupArray[0].name
}

resource rgWorkloadAzureSQL 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: workloadsResourceGroupArray[4].name
}

resource rgExistingSpokeRg 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: spokeNetworkResoureGroupName
}

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  scope: resourceGroup(rgWorkload.name)
  name: managedIdentityName
}

resource keyVault 'Microsoft.KeyVault/vaults@2021-06-01-preview' existing = {
  scope: resourceGroup(rgWorkload.name)
  name: keyVaultName
}

resource spokeVnet 'Microsoft.Network/virtualNetworks@2023-04-01' existing = {
  scope: resourceGroup(rgExistingSpokeRg.name)
  name: spokeVnetName
}

resource spokeNsg 'Microsoft.Network/networkSecurityGroups@2024-01-01' existing = {
  scope: resourceGroup(rgExistingSpokeRg.name)
  name: networksecurityGroupName
}

resource vmNsg 'Microsoft.Network/networkSecurityGroups@2024-01-01' existing = {
  scope: resourceGroup(rgWorkload.name)
  name: vmsecurityGroupName
}

resource virtualMachineSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-01-01' existing = {
  parent: spokeVnet
  name: virtualMachineSubnetName
}

var elasticPoolName = 'elasticpool-${customerName}-${environmentName}-${locationShortCode}-ep-001'

//MARK: SQL Server
@description('SQL Server')
module sqlServer 'br/public:avm/res/sql/server:0.8.0' = if (deploySQLServer) {
  scope: resourceGroup(workloadsResourceGroupArray[4].name)
  name: 'sqlServer-${environmentName}'
  params: {
    name: sqlServerName
    administratorLogin: sqlAdministratorLogin
    administratorLoginPassword: keyVault.getSecret(config.kvSQLPassword)
    managedIdentities: {
      systemAssigned: false
      userAssignedResourceIds: [
        managedIdentity.id
      ]
    }
    primaryUserAssignedIdentityId: managedIdentity.id
    location: location
    tags: tags
    databases: [
      {
        name: 'demodb1'
        maxSizeBytes: 2147483648
        skuName: 'ElasticPool'
        skuTier: 'GeneralPurpose'
        zoneRedundant: false
        capacity: 0
        elasticPoolId: 'subscriptions/${subscriptionId}/resourceGroups/${workloadsResourceGroupArray[4].name}/providers/Microsoft.Sql/servers/${sqlServerName}/elasticpools/${elasticPoolName}'
      }
      {
        name: 'demodb2'
        maxSizeBytes: 2147483648
        skuName: 'ElasticPool'
        skuTier: 'GeneralPurpose'
        zoneRedundant: false
        capacity: 0
        elasticPoolId: 'subscriptions/${subscriptionId}/resourceGroups/${workloadsResourceGroupArray[4].name}/providers/Microsoft.Sql/servers/${sqlServerName}/elasticpools/${elasticPoolName}'
      }
    ]
    elasticPools: [
      {
        maxSizeBytes: 34359738368
        name: elasticPoolName
        perDatabaseSettings: {
          minCapacity: 0
          maxCapacity: 2
        }
        skuCapacity: 2
        skuName: 'GP_Gen5'
        skuTier: 'GeneralPurpose'
        zoneRedundant: false
        maintenanceConfigurationId: '/subscriptions/${subscriptionId}/providers/Microsoft.Maintenance/publicMaintenanceConfigurations/SQL_Default'
      }
    ]
  }
}

// MARK: Virtual machine configuration
param virtualMachinesConfiguration config.appServerType = [
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

//MARK: Virtual Machines
@description('Deploy Virtual Machines')
module virtualMachines 'br/public:avm/res/compute/virtual-machine:0.8.0' = [
  for (vm, index) in virtualMachinesConfiguration: if (deployVMs) {
    scope: resourceGroup(workloadsResourceGroupArray[0].name)
    name: vm.name
    params: {
      name: vm.name
      location: location
      computerName: vm.computerName
      tags: tags
      adminUsername: vm.adminUsername
      adminPassword: keyVault.getSecret(vm.keyVaultSecretName)
      vmSize: vm.vmSize
      encryptionAtHost: false
      zone: 1
      managedIdentities: {
        systemAssigned: false
        userAssignedResourceIds: [
          managedIdentity.id
        ]
      }
      imageReference: vm.imageReference
      osType: vm.osType
      osDisk: {
        diskSizeGB: vm.diskSizeGB
        managedDisk: {
          storageAccountType: 'Premium_LRS' //TODO: fix this to reference vm.storageAccountType
        }
      }
      dataDisks: []
      nicConfigurations: [
        {
          name: 'nic${index}'
          ipConfigurations: [
            {
              name: 'ipconfig${index}'
              subnetResourceId: virtualMachineSubnet.id
              networkSecurityGroup: {
                id: vmNsg.id
              }
            }
          ]
          nicSuffix: '-nic-0${index}'
        }
      ]
    }
  }
]

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
}

//MARK: Storage account
@description('Storage Account')
module storageAccount 'br/public:avm/res/storage/storage-account:0.9.1' = if (deployStorage) {
  scope: resourceGroup(workloadsResourceGroupArray[0].name)
  name: 'storageAccount'
  params: {
    name: storageAccountName
    location: location
    tags: tags
    kind: storageFileShareKind
    skuName: storageFileskuName
    managedIdentities: {
      systemAssigned: false
      userAssignedResourceIds: [
        managedIdentity.id
      ]
    }
    diagnosticSettings: [
      {
        workspaceResourceId: logAnalytics.outputs.resourceId
      }
    ]
    privateEndpoints: [
      {
        name: 'storageAccountPrivateEndpoint-${customerName}-${environmentName}-${locationShortCode}'
        privateDnsZoneResourceIds: [
          '/subscriptions/${hubSubscriptionId}/resourceGroups/${HubResourceGroupPrivateDNSZones}/providers/Microsoft.Network/privateDnsZones/privatelink.file.core.windows.net'
        ]
        subnetResourceId: privateEndpointSubnet.id
        service: 'file'
        tags: tags
      }
    ]
    allowBlobPublicAccess: storageFileShareAllowBlobPublicAccess
    blobServices: {
      containers: [
        {
          name: 'democontainer'
        }
      ]
    }
    networkAcls: {
      bypass: 'AzureServices'
      resourceAccessRules: []
      ipRules: []
      defaultAction: 'Deny'
    }
  }
}

//var loadBalancerPrivateIp = '' cidrHost(vmSubnet.ipRange, 7)''

//MARK: Load balancer
// module loadBalancer 'br/public:avm/res/network/load-balancer:0.4.0' = {
//   scope: resourceGroup(workloadsResourceGroupArray[0].name)
//   name: 'virtualmachineloadbalancer'
//   params: {
//     name: loadbalancerName
//     frontendIPConfigurations: [
//       {
//         name: 'frontendIPConfig'
//         privateIPAllocationMethod: 'Dynamic'
//         //privateIPAddress: loadBalancerPrivateIp
//         subnetId: virtualMachineSubnet.id
//         privateIPAddressVersion: 'IPv4'
//         availabilityZone: 1
//       }
//     ]
//     backendAddressPools: [
//       {
//         name: 'backendAddressPool1'
//       }
//     ]
//     loadBalancingRules: [
//       {
//         name: 'lbRule2'
//         backendAddressPoolName: 'backendAddressPool1'
//         frontendIPConfigurationName: 'frontendIPConfig'
//         protocol: 'Tcp'
//         frontendPort: 80
//         backendPort: 8080
//         enableFloatingIP: false
//         idleTimeoutInMinutes: 4
//         sessionPersistence: 'None'
//         probeName: 'probe'
//         properties: {
//           frontendIPConfiguration: {
//             id: resourceId(
//               'Microsoft.Network/loadBalancers/frontendIpConfigurations',
//               loadbalancerName,
//               'frontendIPConfig'
//             )
//           }
//           backendAddressPool: {
//             id: resourceId(
//               'Microsoft.Network/loadBalancers/backendAddressPools',
//               loadbalancerName,
//               'backendAddressPool1'
//             )
//           }
//           probe: {
//             id: resourceId('Microsoft.Network/loadBalancers/probes', loadbalancerName, 'probe')
//           }
//         }
//       }
//     ]
//     probes: [
//       {
//         name: 'probe'
//         protocol: 'Tcp'
//         port: 8080
//         intervalInSeconds: 5
//         numberOfProbes: 1
//         probeThreshold: 1
//       }
//     ]
//     inboundNatRules: []
//     // // diagnosticSettings: [
//     // //   {
//     // //     workspaceResourceId: logAnalytics.id
//     // //   }
//     // // ]
//     tags: tags
//   }
// }


//MARK: Private Link Service
module privateLinkService 'br/public:avm/res/network/private-link-service:0.2.0' = {
  scope: resourceGroup(workloadsResourceGroupArray[0].name)
  name: privateLinkServiceName
  params: {
    name: privateLinkServiceName
    location: location
    enableProxyProtocol: false
    ipConfigurations: [
      {
        name: 'privatelink-1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: privateLinkSubnet.id
          }
        }
      }
    ]
    loadBalancerFrontendIpConfigurations: [
      {
        id: '/subscriptions/${subscriptionId}/resourceGroups/rg-${customerName}-spoke-${environmentName}-network-${locationShortCode}/providers/Microsoft.Network/loadBalancers/${loadbalancerName}/frontendIPConfigurations/${frontendIPConfigurationsName}'
      }
    ]
    autoApproval: {
      subscriptions: [
        '*'
      ]
    }
    tags: tags
  }
}

//MARK: Create Public IP Address for Application Gateway
@description('Create Public IP Address for Application Gateway')
module createPublicIPAddressForAppGateway 'br/public:avm/res/network/public-ip-address:0.6.0' = {
  scope: resourceGroup(hubSubscriptionId, hubNetworkResoureGroupName)
  name: 'createPublicIPAddressForAppGateway'
  params: {
    name: publicIpAddressForAppGatewayName
    zones: azAppGatewayPip
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
    tags: tags
    diagnosticSettings: [
      {
        workspaceResourceId: logAnalytics.outputs.resourceId
      }
    ]
  }
}

//MARK: App Insights Instance
@description('Create Application Insights Instance')
module createAppInsights 'br/public:avm/res/insights/component:0.4.1' = if (deployWebApps) {
  scope: resourceGroup(workloadsResourceGroupArray[2].name)
  name: 'createAppInsights'
  params: {
    name: appInsightsName
    workspaceResourceId: logAnalytics.outputs.resourceId
    diagnosticSettings: [
      {
        workspaceResourceId: logAnalytics.outputs.resourceId
      }
    ]
  }
  dependsOn: [
    logAnalytics
  ]
}

//MARK: App Service Plan Windows
//Deploy an azure web app with App service plan for Windows
module appServicePlanWindows 'br/public:avm/res/web/serverfarm:0.2.4' = if (deployWebApps) {
  scope: resourceGroup(workloadsResourceGroupArray[2].name)
  name: 'appServicePlanWindows'
  params: {
    name: 'aspwin-${customerName}-${environmentName}-${locationShortCode}'
    location: location
    tags: tags
    skuName: skuNameAppServicePlanWindows
    kind: skuKindAppServicePlanWindows
    skuCapacity: skuCapacityAppServicePlanWindows
    diagnosticSettings: [
      {
        workspaceResourceId: logAnalytics.outputs.resourceId
      }
    ]
  }
  dependsOn: [
    logAnalytics
  ]
}

//MARK: App Service Windows
@description('Deploy an azure web app with App service plan for Windows')
module appServiceWindows 'br/public:avm/res/web/site:0.9.0' = if (deployWebApps) {
  scope: resourceGroup(workloadsResourceGroupArray[2].name)
  name: 'appService'
  params: {
    name: 'appwin-${customerName}-${environmentName}-${locationShortCode}'
    kind: 'app'
    location: location
    tags: tags
    serverFarmResourceId: appServicePlanWindows.outputs.resourceId
    managedIdentities: {
      systemAssigned: false
      userAssignedResourceIds: [
        managedIdentity.id
      ]
    }
    diagnosticSettings: [
      {
        workspaceResourceId: logAnalytics.outputs.resourceId
      }
    ]
    siteConfig: {
      alwaysOn: true
      http20Enabled: false
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: createAppInsights.outputs.instrumentationKey
        }
      ]
    }
    appInsightResourceId: createAppInsights.outputs.resourceId
  }
  dependsOn: [
    logAnalytics
    appServicePlanWindows
    createAppInsights
  ]
}

//MARK: App Service Plan Linux
@description('Deploy an azure web app with App service plan for Linux')
module appServicePlanLinux 'br/public:avm/res/web/serverfarm:0.2.4' = if (deployWebApps) {
  scope: resourceGroup(workloadsResourceGroupArray[2].name)
  name: 'appServicePlanLinux'
  params: {
    name: 'asplinux-${customerName}-${environmentName}-${locationShortCode}'
    location: location
    tags: tags
    skuName: 'P1v3'
    kind: skuKindAppServicePlanLinux
    zoneRedundant: false
    diagnosticSettings: [
      {
        workspaceResourceId: logAnalytics.outputs.resourceId
      }
    ]
  }
  dependsOn: [
    logAnalytics
  ]
}

//MARK: App Service Linux
module appServiceLinux 'br/public:avm/res/web/site:0.9.0' = if (deployWebApps) {
  scope: resourceGroup(workloadsResourceGroupArray[2].name)
  name: 'appServiceLinux'
  params: {
    name: 'applin-${customerName}-${environmentName}-${locationShortCode}'
    kind: 'app'
    location: location
    tags: tags
    serverFarmResourceId: appServicePlanLinux.outputs.resourceId
    managedIdentities: {
      systemAssigned: false
      userAssignedResourceIds: [
        managedIdentity.id
      ]
    }
    diagnosticSettings: [
      {
        workspaceResourceId: logAnalytics.outputs.resourceId
      }
    ]
    siteConfig: {
      alwaysOn: true
      http20Enabled: false
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: createAppInsights.outputs.instrumentationKey
        }
      ]
    }
    appInsightResourceId: createAppInsights.outputs.resourceId
  }
  dependsOn: [
    logAnalytics
    appServicePlanLinux
    createAppInsights
  ]
}

//  Reference existing Azure SQL Server to thet the private ip address
resource existingAzureFirewall 'Microsoft.Network/azureFirewalls@2022-01-01' existing = {
  name: azFirewallName
  scope: resourceGroup(hubSubscriptionId, hubNetworkResoureGroupName)
}

@description('Azure Firewall Policy Rule Collection')
module fireWallPolicyRuleCollection 'br/public:avm/res/network/firewall-policy:0.1.3' = {
  scope: resourceGroup(workloadsResourceGroupArray[0].name)
  name: 'fireWallPolicyRuleCollection'
  params: {
    name: azFirewallPolicyName
    ruleCollectionGroups: [
      {
        name: 'Gregor'
        location: location
        priority: 4000
        ruleCollections: [
          {
            ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
            action: {
              type: 'Allow'
            }
            rules: [
              {
                ruleType: 'ApplicationRule'
                name: 'Ubuntu Updates'
                protocols: [
                  {
                    protocolType: 'Http'
                    port: 8080
                  }
                  {
                    protocolType: 'Https'
                    port: 443
                  }
                ]
                fqdnTags: []
                webCategories: []
                targetFqdns: [
                  '*.ubuntu.com'
                ]
                targetUrls: []
                terminateTLS: false
                sourceAddresses: [
                  '10.128.6.0/24'
                ]
                destinationAddresses: []
                sourceIpGroups: []
                httpHeadersToInsert: []
              }
            ]
            name: 'ServerUpdates'
            priority: 3000 
          }
        ]
      }
    ]
  }
  dependsOn: [
    existingAzureFirewall
  ]
}

//MARK: Azure Firewall Policy
@description('Update Azure Firewall Policy for Intrusion Detection')
module updateAzureFireWallPolicy '../modules/custom/azurefirewallpolicy.bicep' = {
  scope: resourceGroup(rgName)
  name: 'createAzureFireWall'
  params: {
    location: location
    azureFireWallPolicyName: azFirewallPoliciesName
  }
}

//MARK: Azure Firewall Policy Collection Group with Rules
@description('Azure Firewall Policy Collection Group with Rules')
module updateAzureFireWallPolicywithRules '../modules/custom/azurefirewallpolicycollectiongroups.bicep' = {
  scope: resourceGroup(rgName)
  name: 'createAzureFireWall'
  params: {
    firewallPolicyName: 'azfwpolicy-demo-uks'
    appGatewaySubnetAddress: '10.128.6.0/24'
    vmSubnetAddress: '10.200.5.0/26'
  }
}
