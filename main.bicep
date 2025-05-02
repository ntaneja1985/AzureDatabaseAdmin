@description('Specifies the location of the resource')
param location string = 'eastus'

resource sqlServer 'Microsoft.Sql/servers@2014-04-01' ={
  name: uniqueString('sqlserver', resourceGroup().id)
  location: location
  properties: {
    administratorLogin: 'sqladmin'
    administratorLoginPassword: 'P@ssword123'
}
}

resource sqlServerDatabase 'Microsoft.Sql/servers/databases@2014-04-01' = {
  parent: sqlServer
  name: 'DatabaseBicep'
  location: location
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    edition: 'Basic'
    maxSizeBytes: '1073741824'
    requestedServiceObjectiveName: 'Basic'
  }
}
