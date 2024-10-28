param firewallPolicyName string
param appGatewaySubnetAddress string 
param vmSubnetAddress string

resource updateAzureFirewallPolicy 'Microsoft.Network/firewallPolicies@2024-01-01' = {
  name: firewallPolicyName
  location: 'uksouth'
  properties: {
    sku: {
      tier: 'Premium'
    }
    threatIntelMode: 'Deny'
    threatIntelWhitelist: {
      fqdns: []
      ipAddresses: []
    }
    dnsSettings: {
      servers: []
      enableProxy: true
    }
    sql: {
      allowSqlRedirect: false
    }
    intrusionDetection: {
      mode: 'Deny'
      configuration: {
        signatureOverrides: []
        bypassTrafficSettings: []
        privateRanges: [
          '172.16.0.0/12'
          '192.168.0.0/16'
          '100.64.0.0/10'
          '10.0.0.0/9'
          '10.128.0.0/22'
          '10.128.4.0/23'
          '10.128.7.0/24'
          '10.128.8.0/21'
          '10.128.16.0/20'
          '10.128.32.0/19'
          '10.128.64.0/18'
          '10.129.0.0/16'
          '10.130.0.0/15'
          '10.132.0.0/14'
          '10.136.0.0/13'
          '10.144.0.0/12'
          '10.160.0.0/11'
          '10.192.0.0/10'
          '10.128.128.0/17'
        ]
      }
    }
  }
}

resource firewallPolicies_azfwpolicy_demo_uks_name_ServerActivation 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2024-01-01' = {
  parent: updateAzureFirewallPolicy
  name: 'ServerActivation'
  properties: {
    priority: 2900
    ruleCollections: [
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        action: {
          type: 'Allow'
        }
        rules: [
          {
            ruleType: 'NetworkRule'
            name: 'KMS'
            ipProtocols: [
              'TCP'
            ]
            sourceAddresses: [
              appGatewaySubnetAddress //'10.128.6.0/24'
            ]
            sourceIpGroups: []
            destinationAddresses: []
            destinationIpGroups: []
            destinationFqdns: [
              'kms.core.windows.net'
            ]
            destinationPorts: [
              '1688'
            ]
          }
          {
            ruleType: 'NetworkRule'
            name: 'AppGatewaytoCustomer'
            ipProtocols: [
              'TCP'
            ]
            sourceAddresses: [
              appGatewaySubnetAddress //'10.128.6.0/24'
            ]
            sourceIpGroups: []
            destinationAddresses: [
              vmSubnetAddress
            ]
            destinationIpGroups: []
            destinationFqdns: []
            destinationPorts: [
              '8080'
              '443'
            ]
          }
          {
            ruleType: 'NetworkRule'
            name: 'AllowWindowsTimeServer'
            ipProtocols: [
              'UDP'
            ]
            sourceAddresses: [
              '*'
            ]
            sourceIpGroups: []
            destinationAddresses: []
            destinationIpGroups: []
            destinationFqdns: [
              'time.windows.com'
            ]
            destinationPorts: [
              '123'
            ]
          }
          {
            ruleType: 'NetworkRule'
            name: 'AllowAzureBackupAllowMonitor'
            ipProtocols: [
              'TCP'
            ]
            sourceAddresses: [
              '*'
            ]
            sourceIpGroups: []
            destinationAddresses: [
              'AzureBackup'
              'AzureMonitor'
            ]
            destinationIpGroups: []
            destinationFqdns: []
            destinationPorts: [
              '*'
            ]
          }
          {
            ruleType: 'NetworkRule'
            name: 'msedge.api.cdp.microsoft.com'
            ipProtocols: [
              'TCP'
            ]
            sourceAddresses: [
              '*'
            ]
            sourceIpGroups: []
            destinationAddresses: []
            destinationIpGroups: []
            destinationFqdns: [
              'msedge.api.cdp.microsoft.com'
            ]
            destinationPorts: [
              '*'
            ]
          }
          {
            ruleType: 'NetworkRule'
            name: 'AllowLinuxTimeServer'
            ipProtocols: [
              'UDP'
            ]
            sourceAddresses: [
              '*'
            ]
            sourceIpGroups: []
            destinationAddresses: []
            destinationIpGroups: []
            destinationFqdns: [
              'ntp.ubuntu.com'
            ]
            destinationPorts: [
              '*'
            ]
          }
        ]
        name: 'ServerActivation'
        priority: 2900
      }
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
              appGatewaySubnetAddress //'10.128.6.0/24'
            ]
            destinationAddresses: []
            sourceIpGroups: []
            httpHeadersToInsert: []
          }
          {
            ruleType: 'ApplicationRule'
            name: 'Windows Updates'
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
            fqdnTags: [
              'WindowsUpdate'
              'WindowsDiagnostics'
            ]
            webCategories: []
            targetFqdns: []
            targetUrls: []
            terminateTLS: false
            sourceAddresses: [
              appGatewaySubnetAddress //'10.128.6.0/24'
            ]
            destinationAddresses: []
            sourceIpGroups: []
            httpHeadersToInsert: []
          }
          {
            ruleType: 'ApplicationRule'
            name: 'Azure Monitor'
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
              '*.azure.com'
              '*.windows.net'
            ]
            targetUrls: []
            terminateTLS: false
            sourceAddresses: [
              appGatewaySubnetAddress //'10.128.6.0/24'
            ]
            destinationAddresses: []
            sourceIpGroups: []
            httpHeadersToInsert: []
          }
        ]
        name: 'LinuxUpdates'
        priority: 3000
      }
    ]
  }
}

resource firewallPolicies_azfwpolicy_demo_uks_name_TimeSync 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2024-01-01' = {
  parent: updateAzureFirewallPolicy
  name: 'TimeSync'
  properties: {
    priority: 2000
    ruleCollections: [
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        action: {
          type: 'Allow'
        }
        rules: [
          {
            ruleType: 'NetworkRule'
            name: 'TimeSync'
            ipProtocols: [
              'Any'
            ]
            sourceAddresses: [
              appGatewaySubnetAddress //'10.128.6.0/24'
            ]
            sourceIpGroups: []
            destinationAddresses: [
              '*'
            ]
            destinationIpGroups: []
            destinationFqdns: []
            destinationPorts: [
              '123'
            ]
          }
        ]
        name: 'TimeSync'
        priority: 2000
      }
    ]
  }
  dependsOn:[
    firewallPolicies_azfwpolicy_demo_uks_name_ServerActivation
  ]
}
