// This Bicep file is used to deploy the spoke networking resources.

import * as config from '../config.bicep'

metadata name = 'Bicep - Spoke Networking module'
metadata description = 'This module creates spoke networking resources'

targetScope = 'subscription'

param hubName string
param hubSubscriptionId string
var hubNetworkResourceGroup = config.HubResourceGroupNetwork(hubName, environmentName, locationShortCode)
var hubVirtualNetworkName = config.HubVnetName(hubName, environmentName, locationShortCode)

@description('Switch to deploy spoke. defaults to true')
param deploySpoke bool = true

@description('Subscription ID passed in from PowerShell script')
param subscriptionId string = ''

@description('Logged in user details. Passed in from ent "deployNow.ps1" script.')
param updatedBy string = ''

@description('Environment Type: Test, Acceptance/UAT, Production, etc. Passed in from ent "deployNow.ps1" script.')
@allowed([
  'test'
  'dev'
  'prod'
])
param environmentName string = 'test'

@description('The customer name.')
param customerName string

@description('Azure Region to deploy the resources in.')
@allowed([
  'westeurope'
  'northeurope'
  'uksouth'
  'ukwest'
])
param location string = 'westeurope'

@description('Location shortcode. Used for end of resource names.')
param locationShortCode string

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

@description('Global Resource Lock Configuration used for all resources deployed in this module.')
@allowed([
  'CanNotDelete'
  'ReadOnly'
  'None'
])
param globalResourceLock string = 'None'

/*
// Resource Group
*/
@description('Array of resource Groups.')
param spokeResourceGroupArray array = [
  {
    name: 'rg-${customerName}-spoke-${environmentName}-network-${locationShortCode}' //1
    location: location
  }
]

/*
// Azure Networking
*/
// Virtual Network (vNet)
@description('Name for spoke Network.')
param spokeNetworkName string = 'vnet-${customerName}-spoke-${environmentName}-${locationShortCode}'

@description('Array of DNS Server IP addresses for VNet.')
param dnsServerIps array = []

@description('Resource Lock Configuration for Virtual Network.')
@allowed([
  'CanNotDelete'
  'ReadOnly'
  'None'
])
param spokeVirtualNetworkLock string = 'None'

@description('The IP address range for spoke Network.')
param spokeNetworkAddressPrefix string = '10.10.0.0/16'

@description('Name for Azure Bastion Subnet NSG.')
var networksecurityGroupName = 'nsg-${customerName}-spoke-${locationShortCode}'

@sys.description('Id of the DdosProtectionPlan which will be applied to the Virtual Network.')
param ddosProtectionPlanId string = ''

/*
// Azure Private DNS Zones
*/
@description('Switch to enable/disable Private DNS Zones deployment.')
param privateDnsZonesEnabled bool = true

@description('The IP address range for bastion subnet in the virtual networks.')
param virtualmachinesSubnetAddressPrefix string = '10.10.0.0/18'

@description('The IP address range for bastion subnet in the virtual networks.')
param privatelinkSubnetAddressPrefix string = '10.10.64.0/18'


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Deployment modules start here. 

// Get existing Firewall Vnet
resource existingHubVNet 'Microsoft.Network/virtualNetworks@2022-11-01' existing = if (deploySpoke) {
  name: hubVirtualNetworkName
  scope: resourceGroup(hubSubscriptionId, hubNetworkResourceGroup)
}

@description('Deploy Resource Groups')
module spokeResourceGroups 'br/public:avm/res/resources/resource-group:0.4.0' = [
  for (resourceGroup, i) in spokeResourceGroupArray: if (deploySpoke) {
    scope: subscription(subscriptionId)
    name: 'rg-${i}-${customerName}-${environmentName}-${locationShortCode}'
    params: {
      name: resourceGroup.name
      location: resourceGroup.location
      tags: tags
    }
  }
]

@description('Deploy Network Security Group')
module networkSecurityGroup 'br/public:avm/res/network/network-security-group:0.5.0' = if (deploySpoke) {
    scope: resourceGroup(subscriptionId, spokeResourceGroupArray[0].name)
    name: networksecurityGroupName
    params: {
      name: networksecurityGroupName
      location: location
      securityRules: [ ]
      lock: {
        kind: (globalResourceLock != 'None') ? globalResourceLock : spokeVirtualNetworkLock
      }
      tags: tags
    }
    dependsOn: [
      spokeResourceGroups
    ]
}

@description('Deploy Virtual Network')
module spokeVnet 'br/public:avm/res/network/virtual-network:0.4.0' = if (deploySpoke) {
  scope: resourceGroup(subscriptionId, spokeResourceGroupArray[0].name)
  name: spokeNetworkName
  params: {
    name: spokeNetworkName
    location: location
    addressPrefixes: [
      spokeNetworkAddressPrefix
    ]
    subnets: [
      {
        name: 'virtualmachines'
        addressPrefix: virtualmachinesSubnetAddressPrefix
        serviceEndpoints: [
          'Microsoft.Sql'
          'Microsoft.Storage'
        ]
      }
      {
        name: 'privatelink'
        addressPrefix: privatelinkSubnetAddressPrefix
      }
    ]
    peerings: [
      {
        allowForwardedTraffic: true
        allowVirtualNetworkAccess: true
        allowGatewayTransit: false
        useRemoteGateways: false
        remotePeeringEnabled: true
        remotePeeringAllowForwardedTraffic: true
        remoteVirtualNetworkResourceId: existingHubVNet.id
      }
    ]
    dnsServers: dnsServerIps
    ddosProtectionPlanResourceId: (!empty(ddosProtectionPlanId)) ? ddosProtectionPlanId : null
    lock: {
      kind: (globalResourceLock != 'None') ? globalResourceLock : spokeVirtualNetworkLock
    }
    tags: tags
  }
  dependsOn: [
    spokeResourceGroups
  ]
}
