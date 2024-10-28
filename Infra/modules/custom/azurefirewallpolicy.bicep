param location string
param skuTier string = 'Premium'
param threatIntelMode string = 'Deny'
param enableDnsProxy bool = true
param azureFireWallPolicyName string

@description('Azure Firewall Policy with intrsuion detection')
resource updateAzureFirewallPolicy 'Microsoft.Network/firewallPolicies@2024-01-01' = {
  name: azureFireWallPolicyName
  location: location
  properties: {
    sku: {
      tier: skuTier
    }
    threatIntelMode: threatIntelMode
    threatIntelWhitelist: {
      fqdns: []
      ipAddresses: []
    }
    dnsSettings: {
      servers: []
      enableProxy: enableDnsProxy
    }
    intrusionDetection: {
      mode: 'Deny'
      configuration: {
        signatureOverrides: []
        bypassTrafficSettings: []
        privateRanges: [
          '< add example ip addresses >'
        ]
      }
    }
    sql: {
      allowSqlRedirect: false
    }
  }
}
