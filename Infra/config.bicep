// This file is used to store configuration values that are used across the Bicep files in the project.

@export()
var locationShortCodes = {
  westeurope: 'weu'
  uksouth: 'uks'
}

@export()
func HubResourceGroupPrivateDNSZones(hubName string, env string, locationShortCode string) string => 'rg-${hubName}-hub-${env}-private_dns_zones-${locationShortCode}' 
@export()
func HubResourceGroupNetwork(hubName string, env string, locationShortCode string) string => 'rg-${hubName}-hub-${env}-network-${locationShortCode}' 
@export()
func HubResourceGroupFrontdoor(hubName string, env string, locationShortCode string) string => 'rg-${hubName}-hub-${env}-frontdoor-${locationShortCode}' 
@export()
func HubVnetName(hubName string, env string, locationShortCode string) string => 'vnet-${hubName}-hub-${env}-${locationShortCode}'
@export()
func WorkloadResourceGroup(customerName string, env string, locationShortCode string) string => 'rg-${customerName}-${env}-workload-${locationShortCode}' 
@export()
func WorkloadResourceGroupMonitoring(customerName string, env string, locationShortCode string) string => 'rg-${customerName}-${env}-monitoring-${locationShortCode}' 
@export()
func WorkloadWebAppsResourceGroup(customerName string, env string, locationShortCode string) string => 'rg-${customerName}-${env}-webapps-${locationShortCode}' 
@export()
func WorkloadPrivateEndPointsResourceGroup(customerName string, env string, locationShortCode string) string => 'rg-${customerName}-${env}-privateendpoints-${locationShortCode}' 
@export()
func WorkloadAzureSQLResourceGroup(customerName string, env string, locationShortCode string) string => 'rg-${customerName}-${env}-sql-${locationShortCode}' 

@export()
var kvSQLPassword  = 'kvSQLPassword' //TODO: change this to store the secret in KeyVault

@export()
var kvVm1SecretName = 'kvVm1SecretName' 
@export()
var kvVm2SecretName  = 'kvVm2SecretName'


@export()
type appServerType = {
  name: string
  computerName: string
  adminUsername: string
  keyVaultSecretName: string
  vmSize: string
  imageReference: imageReferenceType
  osType: 'Linux' | 'Windows'
  diskSizeGB: int
  storageAccountType: string
  loadbalancerBackendPool: array
  backupEnabled: bool
}[]

type imageReferenceType = {
  publisher: string
  offer: string
  sku: string
  version: string
}
