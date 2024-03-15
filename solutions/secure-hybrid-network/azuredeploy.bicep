targetScope = 'subscription'
param OnPremResourceGroup string = 'site-to-siteon-prem'
param azureNetworkResourceGroup string = 'site-to-site-azure-network'

@description('The admin user name for both the Windows and Linux virtual machines.')
param adminUserName string

@description('The admin password for both the Windows and Linux virtual machines.')
@secure()
param adminPassword string
param resourceGrouplocation string = 'eastus'

resource OnPremResourceGroup_resource 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: OnPremResourceGroup
  location: resourceGrouplocation
}

resource azureNetworkResourceGroup_resource 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: azureNetworkResourceGroup
  location: resourceGrouplocation
}

module onPrem 'nestedtemplates/-onprem-azuredeploy.bicep' = {
  name: 'onPrem'
  scope: OnPremResourceGroup_resource
  params: {
    adminUserName: adminUserName
    adminPassword: adminPassword
    location: resourceGrouplocation
  }
}

module azureNetwork 'nestedtemplates/azure-network-azuredeploy.bicep' = {
  name: 'azureNetwork'
  scope: azureNetworkResourceGroup_resource
  params: {
    adminUserName: adminUserName
    adminPassword: adminPassword
    location: resourceGrouplocation
  }
}

module OnPremLocalGateway 'nestedtemplates/-onprem-local-gateway.bicep' = {
  name: 'OnPremLocalGateway'
  scope: OnPremResourceGroup_resource
  params: {
    gatewayIpAddress: azureNetwork.outputs.vpnIp
    azureCloudVnetPrefix: azureNetwork.outputs.OnpremNetwork
    spokeNetworkAddressPrefix: azureNetwork.outputs.spokeNetworkAddressPrefix
    OnpremGatewayName: onPrem.outputs.OnpremGatewayName
    location: resourceGrouplocation
  }
}

module azureNetworkLocalGateway 'nestedtemplates/azure-network-local-gateway.bicep' = {
  name: 'azureNetworkLocalGateway'
  scope: azureNetworkResourceGroup_resource
  params: {
    azureCloudVnetPrefix: onPrem.outputs.OnpremNetworkPrefix
    gatewayIpAddress: onPrem.outputs.vpnIp
    azureNetworkGatewayName: azureNetwork.outputs.azureGatewayName
    location: resourceGrouplocation
  }
}
