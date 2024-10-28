//This is the main Bicep file for the Hub Networking Module. 
//This file is used to deploy all the resources required for the Hub Networking Module.

import * as config from '../config.bicep'

metadata name = 'Bicep - Hub Networking Module'
metadata description = 'Bicep Module used to set up Hub Networking'

targetScope = 'subscription'

@description('Switch to deploy Hub. defaults to true')
param deployHub bool = true

@description('Subscription ID passed in from PowerShell script')
param subscriptionId string

@description('Logged in user details. Passed in from ent "deployNow.ps1" script.')
param updatedBy string = ''

@description('Environment Type: Test, Acceptance/UAT, Production, etc. Passed in from ent "deployNow.ps1" script.')
@allowed([
  'test'
  'dev'
  'prod'
])
param environmentName string

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
param hubResourceGroupArray array = [
  {
    name: config.HubResourceGroupPrivateDNSZones(customerName, environmentName, locationShortCode)
    location: location
  }
  {
    name: config.HubResourceGroupFrontdoor(customerName, environmentName, locationShortCode) 
    location: location
  }
  {
    name: config.HubResourceGroupNetwork(customerName, environmentName, locationShortCode) 
    location: location
  }
  {
    name: 'rg-${customerName}-hub-${environmentName}-logs-${locationShortCode}' 
    location: location
  }
]

/*
// Monitoring Parameters
*/
// Log Analytics
@description('The name of the Log Analytics used for AKS.')
param aksLAWName string = 'ws-${customerName}-hub-${locationShortCode}'

/*
// Azure Networking
*/
// Virtual Network (vNet)
@description('Name for Hub Network.')
var hubNetworkName = config.HubVnetName(customerName, environmentName, locationShortCode)

@description('Array of DNS Server IP addresses for VNet.')
param dnsServerIps array = []

@description('Resource Lock Configuration for Virtual Network.')
@allowed([
  'CanNotDelete'
  'ReadOnly'
  'None'
])
param hubVirtualNetworkLock string = 'None'

@description('The IP address range for Hub Network.')
param hubNetworkAddressPrefix string = '10.0.0.0/16'

// Subnet
@description('The IP address range for bastion subnet in the virtual networks.')
param bastionsubnetAddressPrefix string = '10.0.1.0/24'

@description('The IP address range for gateway subnet in the virtual networks.')
param gatewaySubnetaddressPrefix string = '10.0.2.0/24'

@description('The IP address range for firewall subnet in the virtual networks.')
param azureFirewallSubnetaddressPrefix string = '10.0.3.0/24'

@description('The IP address range for firewall managment (basic only) subnet in the virtual networks.')
param azureFirewallManagementSubnetaddressPrefix string = '10.0.4.0/24'

@description('The IP address range for private endpoint subnet in the virtual networks.')
param privateEndPointSubnetaddressPrefix string = '10.0.5.0/24'

@description('Switch to enable/disable private endpoint subnet deployment.')
param privateEndPointEnabled bool = true

// Public IP
@description('Public IP Address SKU.')
@allowed([
  'Basic'
  'Standard'
])
param publicIpSku string = 'Standard'

@description('Optional Prefix for Public IPs. Include a succedent dash if required. Example: prefix-')
param publicIpPrefix string = 'pip-'

@description('Optional Suffix for Public IPs. Include a preceding dash if required. Example: -suffix')
param publicIpSuffix string = '-${locationShortCode}'

/*
// Azure Bastion
*/
@description('Switch to enable/disable Azure Bastion deployment.')
param bastionEnabled bool = true

@description('Name Associated with Bastion Service.')
param bastionName string = 'bas-${customerName}-${locationShortCode}'

@description('Azure Bastion SKU.')
@allowed([
  'Basic'
  'Standard'
])
param bastionSku string = 'Standard'

@description('Name for Azure Bastion Subnet NSG.')
param bastionNsgName string = 'nsg-AzureBastionSubnet'

@description('Define outbound destination ports or ranges for SSH or RDP that you want to access from Azure Bastion.')
param bastionOutboundSshRdpPorts array = ['22', '3389']

@description('Resource Lock Configuration for Bastion.')
@allowed([
  'CanNotDelete'
  'ReadOnly'
  'None'
])
param bastionLock string = 'None'

/*
// Azure DDOS
*/
@description('Switch to enable/disable DDoS Network Protection deployment.')
param ddosEnabled bool = false

@description('DDoS Plan Name.')
param ddosPlanName string = 'ddos-${customerName}-${locationShortCode}'

@description('Resource Lock Configuration for DDoS Plan.')
@allowed([
  'CanNotDelete'
  'ReadOnly'
  'None'
])
param ddosLock string = 'None'

/*
// Azure Firewall
*/
@description('Switch to enable/disable Azure Firewall deployment.')
param azFirewallEnabled bool = true

@description('Azure Firewall Name.')
param azFirewallName string = 'azfw-${customerName}-${locationShortCode}'

@description('Azure Firewall Policies Name.')
param azFirewallPoliciesName string = 'azfwpolicy-${customerName}-${locationShortCode}'

@description('Azure Firewall Tier associated with the Firewall to deploy.')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param azFirewallTier string = 'Premium'

@description('The Azure Firewall Threat Intelligence Mode. If not set, the default value is Alert.')
@allowed([
  'Alert'
  'Deny'
  'Off'
])
param azFirewallIntelMode string = 'Alert'

@allowed([
  1
  2
  3
])
@description('Availability Zones to deploy the Azure Firewall across. Region must support Availability Zones to use. If it does not then leave empty.')
param azFirewallAvailabilityZones array = []

@description('Switch to enable/disable Azure Firewall DNS Proxy.')
param azFirewallDnsProxyEnabled bool = true

@description('Array of custom DNS servers used by Azure Firewall')
param azFirewallDnsServers array = []

@allowed([
  'AzureFirewallApplicationRule'
  'AzureFirewallNetworkRule'
  'AzureFirewallDnsProxy'
  'AZFWNetworkRule'
  'AZFWApplicationRule'
  'AZFWNatRule'
  'AZFWThreatIntel'
  'AZFWIdpsSignature'
  'AZFWDnsQuery'
  'AZFWFqdnResolveFailure'
  'AZFWApplicationRuleAggregation'
  'AZFWNetworkRuleAggregation'
  'AZFWNatRuleAggregation'
  null
])
param azFwDiagnosticLogCategories array = [
  'AzureFirewallApplicationRule'
  'AzureFirewallNetworkRule'
  'AzureFirewallDnsProxy'
  'AZFWNetworkRule'
  'AZFWApplicationRule'
  'AZFWNatRule'
  'AZFWThreatIntel'
  'AZFWIdpsSignature'
  'AZFWDnsQuery'
  'AZFWFqdnResolveFailure'
  'AZFWApplicationRuleAggregation'
  'AZFWNetworkRuleAggregation'
  'AZFWNatRuleAggregation'
]

var firewallLogCategoriesConfig = [
  for category in azFwDiagnosticLogCategories: {
    category: category
  }
]

@description('Resource Lock Configuration for Azure Firewall.')
@allowed([
  'CanNotDelete'
  'ReadOnly'
  'None'
])
param azureFirewallLock string = 'None'

/*
// Route Table
*/
@description('Name of Route table to create for the default route of Hub.')
param hubRouteTableName string = 'rt-${customerName}-hub-${locationShortCode}'

@description('Switch to enable/disable BGP Propagation on route table.')
param disableBgpRoutePropagation bool = false

@description('Resource Lock Configuration for Hub Route Table.')
@allowed([
  'CanNotDelete'
  'ReadOnly'
  'None'
])
param hubRouteTableLock string = 'None'

/*
// Azure Private DNS Zones
*/
@description('Switch to enable/disable Private DNS Zones deployment.')
param privateDnsZonesEnabled bool = true

@description('Array of DNS Zones to provision in Hub Virtual Network. Default: All known Azure Private DNS Zones')
param privateDNSZonesArray array = [
  'privatelink.analysis.windows.net'
  'privatelink.api.azureml.ms'
  'privatelink.azconfig.io'
  'privatelink.azure-api.net'
  'privatelink.azure-automation.net'
  'privatelink.azurecr.io'
  'privatelink.azure-devices.net'
  'privatelink.azure-devices-provisioning.net'
  'privatelink.azuredatabricks.net'
  'privatelink.azurehealthcareapis.com'
  'privatelink.azurestaticapps.net'
  'privatelink.azuresynapse.net'
  'privatelink.azurewebsites.net'
  'privatelink.batch.azure.com'
  #disable-next-line no-hardcoded-env-urls
  'privatelink.blob.core.windows.net'
  'privatelink.cassandra.cosmos.azure.com'
  'privatelink.cognitiveservices.azure.com'
  #disable-next-line no-hardcoded-env-urls
  'privatelink.database.windows.net'
  'privatelink.datafactory.azure.net'
  'privatelink.dev.azuresynapse.net'
  #disable-next-line no-hardcoded-env-urls
  'privatelink.dfs.core.windows.net'
  #disable-next-line no-hardcoded-env-urls
  'privatelink.file.core.windows.net'
  'privatelink.monitor.azure.com'
  #disable-next-line no-hardcoded-env-urls
  'privatelink.queue.core.windows.net'
  'privatelink.redis.cache.windows.net'
  'privatelink.redisenterprise.cache.azure.net'
  'privatelink.search.windows.net'
  'privatelink.service.signalr.net'
  'privatelink.servicebus.windows.net'
  'privatelink.siterecovery.windowsazure.com'
  'privatelink.sql.azuresynapse.net'
  #disable-next-line no-hardcoded-env-urls
  'privatelink.table.core.windows.net'
  'privatelink.table.cosmos.azure.com'  
  'privatelink.vaultcore.azure.net'
  #disable-next-line no-hardcoded-env-urls
  'privatelink.web.core.windows.net'
]

@description('Resource Lock Configuration for Private DNS Zone(s).')
@allowed([
  'CanNotDelete'
  'ReadOnly'
  'None'
])
param privateDNSZonesLock string = 'None'

/*
// Azure Virtual Network Gateway (VPN)
*/
@description('Switch to enable/disable VPN virtual network gateway deployment.')
param vpnGatewayEnabled bool = false

//ASN must be 65515 if deploying VPN & ER for co-existence to work: https://docs.microsoft.com/en-us/azure/expressroute/expressroute-howto-coexist-resource-manager#limits-and-limitations
@description('Configuration for VPN virtual network gateway to be deployed.')
param vpnGatewayConfig object = {
  name: 'vgw-${customerName}-${locationShortCode}'
  gatewayType: 'Vpn'
  sku: 'VpnGw1'
  vpnType: 'RouteBased'
  generation: 'Generation1'
  enableBgp: false
  activeActive: false
  enableBgpRouteTranslationForNat: false
  enableDnsForwarding: false
  bgpPeeringAddress: ''
  bgpsettings: {
    asn: 65515
    bgpPeeringAddress: ''
    peerWeight: 5
  }
  vpnClientConfiguration: {}
}

@allowed([
  1
  2
  3
])
@description('Availability Zones to deploy the VPN/ER PIP across. Region must support Availability Zones to use. If it does not then leave empty. Ensure that you select a zonal SKU for the ER/VPN Gateway if using Availability Zones for the PIP.')
param azVpnGatewayAvailabilityZones array = []

@description('Switch to enable/disable ExpressRoute virtual network gateway deployment.')
param expressRouteGatewayEnabled bool = false

@description('Configuration for ExpressRoute virtual network gateway to be deployed.')
param expressRouteGatewayConfig object = {
  name: 'ergw-${customerName}-${locationShortCode}'
  gatewayType: 'ExpressRoute'
  sku: 'ErGw1AZ'
  vpnType: 'RouteBased'
  vpnGatewayGeneration: 'None'
  enableBgp: false
  activeActive: false
  enableBgpRouteTranslationForNat: false
  enableDnsForwarding: false
  bgpPeeringAddress: ''
  bgpsettings: {
    asn: '65515'
    bgpPeeringAddress: ''
    peerWeight: '5'
  }
}

@allowed([
  1
  2
  3
])
@description('Availability Zones to deploy the VPN/ER PIP across. Region must support Availability Zones to use. If it does not then leave empty. Ensure that you select a zonal SKU for the ER/VPN Gateway if using Availability Zones for the PIP.')
param azErGatewayAvailabilityZones array = []

@description('Resource Lock Configuration for ExpressRoute Virtual Network Gateway.')
@allowed([
  'CanNotDelete'
  'ReadOnly'
  'None'
])
param virtualNetworkGatewayLock string = 'None'

var vpnGwConfig = ((vpnGatewayEnabled) && (!empty(vpnGatewayConfig))
  ? vpnGatewayConfig
  : json('{"name": "noconfigVpn"}'))

var erGwConfig = ((expressRouteGatewayEnabled) && !empty(expressRouteGatewayConfig)
  ? expressRouteGatewayConfig
  : json('{"name": "noconfigEr"}'))

var varGwConfig = [
  vpnGwConfig
  erGwConfig
]

/*
// Azure Front Door
*/
@description('Switch to enable/disable Azure Front Door deployment.')
param afdWAFEnabled bool = true

@description('Name Associated with Azure Front Door.')
param afdName string = 'afd-${customerName}-hub-${environmentName}-${locationShortCode}'

@description('Azure Front Door Sku')
@allowed([
  'Standard_AzureFrontDoor'
  'Premium_AzureFrontDoor'
])
param afdSKU string = 'Premium_AzureFrontDoor'

@allowed([
  'FrontDoorAccessLog'
  'FrontDoorWebApplicationFirewallLog'
  'FrontDoorHealthProbeLog'
])
param afdDiagnosticLogCategories array = [
  'FrontDoorAccessLog'
  'FrontDoorWebApplicationFirewallLog'
  'FrontDoorHealthProbeLog'
]

var frontDoorLogCategoriesConfig = [
  for category in afdDiagnosticLogCategories: {
    category: category
  }
]

@description('Required. Name of the Front Door WAF policy.')
@minLength(1)
@maxLength(128)
param afdWafPolicyName string = 'fdfp${customerName}hub${environmentName}${locationShortCode}'

@allowed([
  'Standard_AzureFrontDoor'
  'Premium_AzureFrontDoor'
])
@description('The pricing tier of the WAF profile.')
param afdWAFPolicySKU string = 'Premium_AzureFrontDoor'

@description('The WAF Policy mode.')
@allowed([
  'Detection'
  'Prevention'
])
param afdWAFPolicyMode string = 'Detection'

@description('Resource Lock Configuration for Front Door.')
@allowed([
  'CanNotDelete'
  'ReadOnly'
  'None'
])
param frontDoorLock string = 'None'

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Deploy required Resource Groups - New Resources 
module hubResourceGroups 'br/public:avm/res/resources/resource-group:0.4.0' = [
  for (resourceGroup, i) in hubResourceGroupArray: if (deployHub) {
    scope: subscription(subscriptionId)
    name: 'rg-${i}-${customerName}-${environmentName}-${locationShortCode}'
    params: {
      name: resourceGroup.name
      location: resourceGroup.location
      tags: tags
    }
  }
]

// Deploy required Log Analytics Workspace
module aksLAW 'br/public:avm/res/operational-insights/workspace:0.7.0' =
  if (deployHub) {
    scope: resourceGroup(subscriptionId, hubResourceGroupArray[3].name)
    name: aksLAWName
    params: {
      name: aksLAWName
      location: location
      tags: tags
    }
    dependsOn: [
      hubResourceGroups
    ]
  }

//DDos Protection plan will only be enabled if ddosEnabled is true.
module ddosProtectionPlan 'br/public:avm/res/network/ddos-protection-plan:0.3.0' =
  if (ddosEnabled && deployHub) {
    scope: resourceGroup(subscriptionId, hubResourceGroupArray[2].name)
    name: ddosPlanName
    params: {
      name: ddosPlanName
      location: location
      lock: {
        kind: (globalResourceLock != 'None') ? globalResourceLock : ddosLock
      }
      tags: tags
    }
    dependsOn: [
      hubResourceGroups
    ]
  }

module bastionNsg 'br/public:avm/res/network/network-security-group:0.5.0' =
  if (bastionEnabled && deployHub) {
    scope: resourceGroup(subscriptionId, hubResourceGroupArray[2].name)
    name: bastionNsgName
    params: {
      name: bastionNsgName
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
          name: 'AllowGatewayManagerInbound'
          properties: {
            access: 'Allow'
            direction: 'Inbound'
            priority: 130
            sourceAddressPrefix: 'GatewayManager'
            destinationAddressPrefix: '*'
            protocol: 'Tcp'
            sourcePortRange: '*'
            destinationPortRange: '443'
          }
        }
        {
          name: 'AllowAzureLoadBalancerInbound'
          properties: {
            access: 'Allow'
            direction: 'Inbound'
            priority: 140
            sourceAddressPrefix: 'AzureLoadBalancer'
            destinationAddressPrefix: '*'
            protocol: 'Tcp'
            sourcePortRange: '*'
            destinationPortRange: '443'
          }
        }
        {
          name: 'AllowBastionHostCommunication'
          properties: {
            access: 'Allow'
            direction: 'Inbound'
            priority: 150
            sourceAddressPrefix: 'VirtualNetwork'
            destinationAddressPrefix: 'VirtualNetwork'
            protocol: 'Tcp'
            sourcePortRange: '*'
            destinationPortRanges: [
              '8080'
              '5701'
            ]
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
          name: 'AllowSshRdpOutbound'
          properties: {
            access: 'Allow'
            direction: 'Outbound'
            priority: 100
            sourceAddressPrefix: '*'
            destinationAddressPrefix: 'VirtualNetwork'
            protocol: '*'
            sourcePortRange: '*'
            destinationPortRanges: bastionOutboundSshRdpPorts
          }
        }
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
          name: 'AllowBastionCommunication'
          properties: {
            access: 'Allow'
            direction: 'Outbound'
            priority: 120
            sourceAddressPrefix: 'VirtualNetwork'
            destinationAddressPrefix: 'VirtualNetwork'
            protocol: '*'
            sourcePortRange: '*'
            destinationPortRanges: [
              '8080'
              '5701'
            ]
          }
        }
        {
          name: 'AllowGetSessionInformation'
          properties: {
            access: 'Allow'
            direction: 'Outbound'
            priority: 130
            sourceAddressPrefix: '*'
            destinationAddressPrefix: 'Internet'
            protocol: '*'
            sourcePortRange: '*'
            destinationPortRange: '80'
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
      lock: {
        kind: (globalResourceLock != 'None') ? globalResourceLock : bastionLock
      }
      tags: tags
    }
    dependsOn: [
      hubResourceGroups
    ]
  }

module hubVnet 'br/public:avm/res/network/virtual-network:0.4.0' =
  if (deployHub) {
    scope: resourceGroup(subscriptionId, hubResourceGroupArray[2].name)
    name: hubNetworkName
    params: {
      name: hubNetworkName
      location: location
      addressPrefixes: [
        hubNetworkAddressPrefix
      ]
      dnsServers: dnsServerIps
      ddosProtectionPlanResourceId: (ddosEnabled) ? ddosProtectionPlan.outputs.resourceId : null
      lock: {
        kind: (globalResourceLock != 'None') ? globalResourceLock : hubVirtualNetworkLock
      }
      subnets: [
        {
          name: 'AzureBastionSubnet'
          addressPrefix: bastionsubnetAddressPrefix
          networkSecurityGroupResourceId: bastionNsg.outputs.resourceId
        }
        {
          name: 'GatewaySubnet'
          addressPrefix: gatewaySubnetaddressPrefix
        }
        {
          name: 'AzureFirewallSubnet'
          addressPrefix: azureFirewallSubnetaddressPrefix
        }
        {
          name: 'AzureFirewallManagementSubnet'
          addressPrefix: azureFirewallManagementSubnetaddressPrefix
        }
        {
          name: 'PrivateEndPointSubnet'
          addressPrefix: privateEndPointSubnetaddressPrefix
        }
      ]
      tags: tags
    }
    dependsOn: [
      hubResourceGroups
    ]
  }

//MARK: Private DNS Zones
@description('Private DNS Zones')
module privateDnsZones 'br/public:avm/res/network/private-dns-zone:0.6.0' = [
  for zone in privateDNSZonesArray: if (privateDnsZonesEnabled && deployHub) {
    name: 'deploy-private-dns-${zone}'
    scope: resourceGroup(subscriptionId, hubResourceGroupArray[0].name)
    params: {
      name: zone
      location: 'global'
      tags: tags
      virtualNetworkLinks: [
        {
          virtualNetworkResourceId: hubVnet.outputs.resourceId
        }
      ]
      lock: {
        kind: (globalResourceLock != 'None') ? globalResourceLock : privateDNSZonesLock
      }
    }
    dependsOn: [
      hubResourceGroups
      hubVnet
    ]
  }
]

//MARK: Azure Bastion Public IP
@description('Azure Bastion Public IP')
module bastionPublicIp 'br/public:avm/res/network/public-ip-address:0.6.0' =
  if (bastionEnabled && deployHub) {
    scope: resourceGroup(subscriptionId, hubResourceGroupArray[2].name)
    name: 'deploy-Bastion-Public-IP'
    params: {
      location: location
      name: '${publicIpPrefix}${bastionName}${publicIpSuffix}'
      skuName: publicIpSku
      publicIPAddressVersion: 'IPv4'
      publicIPAllocationMethod: 'Static'
      lock: {
        kind: (globalResourceLock != 'None') ? globalResourceLock : bastionLock
      }
      tags: tags
    }
    dependsOn: [
      hubResourceGroups
    ]
  }

// AzureBastionSubnet is required to deploy Bastion service. This subnet must exist in the subnets array if you enable Bastion Service.
// There is a minimum subnet requirement of /27 prefix.
// If you are deploying standard this needs to be larger. https://docs.microsoft.com/en-us/azure/bastion/configuration-settings#subnet
//MARK: Azure Bastion
@description('Azure Bastion')
module bastion 'br/public:avm/res/network/bastion-host:0.4.0' =
  if (bastionEnabled && deployHub) {
    scope: resourceGroup(subscriptionId, hubResourceGroupArray[2].name)
    name: bastionName
    params: {
      name: bastionName
      location: location
      skuName: bastionSku
      bastionSubnetPublicIpResourceId: bastionEnabled ? bastionPublicIp.outputs.resourceId : ''
      virtualNetworkResourceId: hubVnet.outputs.resourceId
      lock: {
        kind: (globalResourceLock != 'None') ? globalResourceLock : bastionLock
      }
      tags: tags
    }
    dependsOn: [
      hubVnet
      bastionPublicIp
    ]
  }

//MARK: Azure Firewall Public IP
@description('Azure Firewall Public IP')
module azureFirewallPublicIp 'br/public:avm/res/network/public-ip-address:0.6.0' =
  if (azFirewallEnabled && deployHub) {
    scope: resourceGroup(subscriptionId, hubResourceGroupArray[2].name)
    name: 'deploy-Firewall-Public-IP'
    params: {
      location: location
      zones: azFirewallAvailabilityZones
      name: '${publicIpPrefix}${azFirewallName}${publicIpSuffix}'
      skuName: publicIpSku
      publicIPAddressVersion: 'IPv4'
      publicIPAllocationMethod: 'Static'
      lock: {
        kind: (globalResourceLock != 'None') ? globalResourceLock : azureFirewallLock
      }
      tags: tags
    }
    dependsOn: [
      hubResourceGroups
    ]
  }

//MARK: Azure Firewall Management Public IP Address
@description('Azure Firewall Management Public IP Address')
module azureFirewallMgmtPublicIp 'br/public:avm/res/network/public-ip-address:0.6.0' =
  if (azFirewallEnabled && azFirewallTier == 'Basic' && deployHub) {
    scope: resourceGroup(subscriptionId, hubResourceGroupArray[2].name)
    name: 'deploy-Firewall-mgmt-Public-IP'
    params: {
      location: location
      zones: azFirewallAvailabilityZones
      name: '${publicIpPrefix}${azFirewallName}-mgmt${publicIpSuffix}'
      skuName: publicIpSku
      publicIPAddressVersion: 'IPv4'
      publicIPAllocationMethod: 'Static'
      lock: {
        kind: (globalResourceLock != 'None') ? globalResourceLock : azureFirewallLock
      }
      tags: tags
    }
    dependsOn: [
      hubResourceGroups
    ]
  }

//MARK: Azure Firewall Policies
@description('Azure Firewall Policies')
module firewallPolicies 'br/public:avm/res/network/firewall-policy:0.1.3' =
  if (azFirewallEnabled && deployHub) {
    scope: resourceGroup(subscriptionId, hubResourceGroupArray[2].name)
    name: azFirewallPoliciesName
    params: {
      name: azFirewallPoliciesName
      location: location
      tier: azFirewallTier
      insightsIsEnabled: true
      defaultWorkspaceId: aksLAW.outputs.resourceId
      threatIntelMode: (azFirewallTier == 'Basic') ? 'Alert' : azFirewallIntelMode
      enableProxy: (azFirewallTier == 'Basic') ? false : azFirewallDnsProxyEnabled
      servers: (azFirewallTier == 'Basic') ? null : azFirewallDnsServers
      tags: tags
    }
    dependsOn: [
      hubResourceGroups
    ]
  }

// AzureFirewallSubnet is required to deploy Azure Firewall . This subnet must exist in the subnets array if you deploy.
// There is a minimum subnet requirement of /26 prefix.
//MARK: Azure Firewall
@description('Azure Firewall')
module azureFirewall 'br/public:avm/res/network/azure-firewall:0.5.0' =
  if (azFirewallEnabled && deployHub) {
    scope: resourceGroup(subscriptionId, hubResourceGroupArray[2].name)
    name: azFirewallName
    params: {
      name: azFirewallName
      location: location
      zones: (!empty(azFirewallAvailabilityZones) ? azFirewallAvailabilityZones : [])
      virtualNetworkResourceId: hubVnet.outputs.resourceId
      publicIPResourceID: azFirewallEnabled ? azureFirewallPublicIp.outputs.resourceId : ''
      managementIPResourceID: (azFirewallEnabled && azFirewallTier == 'Basic')
        ? azureFirewallMgmtPublicIp.outputs.resourceId
        : ''
      azureSkuTier: azFirewallTier
      firewallPolicyId: firewallPolicies.outputs.resourceId
      diagnosticSettings: [
        {
          workspaceResourceId: aksLAW.outputs.resourceId
          logCategoriesAndGroups: firewallLogCategoriesConfig
        }
      ]
      lock: {
        kind: (globalResourceLock != 'None') ? globalResourceLock : azureFirewallLock
      }
      tags: tags
    }
    dependsOn: [
      azureFirewallMgmtPublicIp
      azureFirewallPublicIp
    ]
  }


//If Azure Firewall is enabled we will deploy a RouteTable to redirect Traffic to the Firewall.
//MARK: Hub Route Table
@description('Hub Route Table')
module hubrouteTable 'br/public:avm/res/network/route-table:0.4.0' =
  if (azFirewallEnabled && deployHub) {
    scope: resourceGroup(subscriptionId, hubResourceGroupArray[2].name)
    name: hubRouteTableName
    params: {
      name: hubRouteTableName
      location: location
      routes: [
        {
          name: 'udr-default-azfw'
          properties: {
            nextHopType: 'VirtualAppliance'
            addressPrefix: '0.0.0.0/0'
            nextHopIpAddress: azFirewallEnabled ? azureFirewall.outputs.privateIp : ''
          }
        }
      ]
      disableBgpRoutePropagation: disableBgpRoutePropagation
      lock: {
        kind: (globalResourceLock != 'None') ? globalResourceLock : hubRouteTableLock
      }
      tags: tags
    }
    dependsOn: [
      azureFirewall
      hubResourceGroups
    ]
  }


//MARK: Gateway Public IP Address
@description('Gateway Public IP Address')
module gatewayPublicIp 'br/public:avm/res/network/public-ip-address:0.6.0' = [
  for (gateway, i) in varGwConfig: if ((gateway.name != 'noconfigVpn') && (gateway.name != 'noconfigEr') && deployHub) {
    name: 'deploy-Gateway-Public-IP-${i}'
    scope: resourceGroup(subscriptionId, hubResourceGroupArray[2].name)
    params: {
      location: location
      zones: toLower(gateway.gatewayType) == 'expressroute'
        ? azErGatewayAvailabilityZones
        : toLower(gateway.gatewayType) == 'vpn' ? azVpnGatewayAvailabilityZones : []
      name: '${publicIpPrefix}${gateway.name}${publicIpSuffix}'
      skuName: publicIpSku
      publicIPAddressVersion: 'IPv4'
      publicIPAllocationMethod: 'Static'
      lock: {
        kind: (globalResourceLock != 'None') ? globalResourceLock : virtualNetworkGatewayLock
      }
      tags: tags
    }
    dependsOn: [
      hubResourceGroups
    ]
  }
]

//MARK: Azure Front Door WAF Policy
@description('Azure Front Door WAF Policy')
module wafPolicy 'br/public:avm/res/network/front-door-web-application-firewall-policy:0.3.0' =
  if (afdWAFEnabled && deployHub) {
    scope: resourceGroup(subscriptionId, hubResourceGroupArray[1].name)
    name: afdWafPolicyName
    params: {
      name: afdWafPolicyName
      location: 'global'
      sku: afdWAFPolicySKU
      policySettings: {
        enabledState: 'Enabled'
        mode: afdWAFPolicyMode
      }
      lock: {
        kind: (globalResourceLock != 'None') ? globalResourceLock : frontDoorLock
      }
      tags: tags
    }
    dependsOn: [
      hubResourceGroups
    ]
  }

//MARK: Azure Front Door  
@description('Azure Front Door')
module azureFrontDoor '../../Infra/modules/cdn/profile/main.bicep' =
  if (afdWAFEnabled && deployHub) {
    scope: resourceGroup(subscriptionId, hubResourceGroupArray[1].name)
    name: afdName
    params: {
      name: afdName
      sku: afdSKU
      location: 'global'
      afdEndpoints: [
        {
          name: 'afep${customerName}hub${environmentName}'
          wafPolicyIdd: afdWAFEnabled ? wafPolicy.outputs.resourceId : ''
          securityPolicyName: afdWafPolicyName
        }
      ]
      lock: {
        kind: (globalResourceLock != 'None') ? globalResourceLock : frontDoorLock
      }
      tags: tags
    }
  }


  