using 'hub.bicep'

import * as config from '../config.bicep'

param deployHub = true //deploy hub resources
param afdWAFEnabled = false //deploy Azure Front Door and WAF
param azFirewallEnabled = true //deploy Azure Firewall

param subscriptionId = ''
param updatedBy = ''
param environmentName = 'test'
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
param hubResourceGroupArray = [
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
param aksLAWName = 'ws-${customerName}-hub-${locationShortCode}'
param dnsServerIps = []
param hubVirtualNetworkLock = 'None'
param hubNetworkAddressPrefix = '10.0.0.0/16'
param bastionsubnetAddressPrefix = '10.0.1.0/24'
param gatewaySubnetaddressPrefix = '10.0.2.0/24'
param azureFirewallSubnetaddressPrefix = '10.0.3.0/24'
param azureFirewallManagementSubnetaddressPrefix = '10.0.4.0/24'
param privateEndPointSubnetaddressPrefix = '10.0.5.0/24'
param privateEndPointEnabled = true
param publicIpSku = 'Standard'
param publicIpPrefix = 'pip-'
param publicIpSuffix = '-${locationShortCode}'
param bastionEnabled = true
param bastionName = 'bas-${customerName}-${locationShortCode}'
param bastionSku = 'Standard'
param bastionNsgName = 'nsg-AzureBastionSubnet'
param bastionOutboundSshRdpPorts = [
  '22'
  '3389'
]
param bastionLock = 'None'
param ddosEnabled = false
param ddosPlanName = 'ddos-${customerName}-${locationShortCode}'
param ddosLock = 'None'

param azFirewallName = 'azfw-${customerName}-${locationShortCode}'
param azFirewallPoliciesName = 'azfwpolicy-${customerName}-${locationShortCode}'
param azFirewallTier = 'Premium'
param azFirewallIntelMode = 'Alert'
param azFirewallAvailabilityZones = []
param azFirewallDnsProxyEnabled = true
param azFirewallDnsServers = []
param azFwDiagnosticLogCategories = [
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
param azureFirewallLock = 'None'
param hubRouteTableName = 'rt-${customerName}-hub-${locationShortCode}'
param disableBgpRoutePropagation = false
param hubRouteTableLock = 'None'
param privateDnsZonesEnabled = true
param privateDNSZonesArray = [
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
  'privatelink.blob.core.windows.net'
  'privatelink.cassandra.cosmos.azure.com'
  'privatelink.cognitiveservices.azure.com'
  'privatelink.database.windows.net'
  'privatelink.datafactory.azure.net'
  'privatelink.dev.azuresynapse.net'
  'privatelink.dfs.core.windows.net'
  'privatelink.file.core.windows.net'
  'privatelink.monitor.azure.com'
  'privatelink.queue.core.windows.net'
  'privatelink.redis.cache.windows.net'
  'privatelink.redisenterprise.cache.azure.net'
  'privatelink.search.windows.net'
  'privatelink.service.signalr.net'
  'privatelink.servicebus.windows.net'
  'privatelink.siterecovery.windowsazure.com'
  'privatelink.sql.azuresynapse.net'
  'privatelink.table.core.windows.net'
  'privatelink.table.cosmos.azure.com'  
  'privatelink.vaultcore.azure.net'
  'privatelink.web.core.windows.net'
]
param privateDNSZonesLock = 'None'
param vpnGatewayEnabled = false
param vpnGatewayConfig = {
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
param azVpnGatewayAvailabilityZones = []
param expressRouteGatewayEnabled = false
param expressRouteGatewayConfig = {
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
param azErGatewayAvailabilityZones = []
param virtualNetworkGatewayLock = 'None'

param afdName = 'afd-${customerName}-hub-${environmentName}-${locationShortCode}'
param afdSKU = 'Premium_AzureFrontDoor'
param afdDiagnosticLogCategories = [
  'FrontDoorAccessLog'
  'FrontDoorWebApplicationFirewallLog'
  'FrontDoorHealthProbeLog'
]
param afdWafPolicyName = 'fdfp${customerName}hub${environmentName}${locationShortCode}'
param afdWAFPolicySKU = 'Premium_AzureFrontDoor'
param afdWAFPolicyMode = 'Detection'
param frontDoorLock = 'None'

