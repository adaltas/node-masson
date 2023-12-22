
normalize = require 'masson/config/normalize'
store = require 'masson/config/store'
array_get = require 'masson/utils/array_get'
nikita = require 'nikita'

describe 'chrony config', ->

  tmp = '/tmp/masson-test'
  beforeEach ->
    require('module')._cache = {}
    nikita
    .system.mkdir target: tmp
    .promise()
  afterEach ->
    nikita
    .system.remove tmp
    .promise()
  
  describe 'normalize', ->
    
    it 'pass config as a string', ->
      store normalize
        clusters: 'test': services: 'chrony':
          module: 'masson/core/chrony'
          options:
            config: """
            allow 192.168/16
            local stratum 10
            manual
            """
      .service 'test', 'chrony'
      .options.should.eql
        config: """
        allow 192.168/16
        local stratum 10
        manual
        """
          
    it 'distinct config between server and client', ->
      store normalize
        clusters: 'test': services: 'chrony':
          module: 'masson/core/chrony'
          affinity: type: 'nodes', match: 'any', values: ['server.fqdn', 'client.fqdn']
          options:
            server: "server.fqdn"
            server_config: """
            allow 192.168/16
            local stratum 10
            manual
            """
            client_config: """
            server 192.168.122.1 iburst
            """
        nodes:
          'server.fqdn': ip: '192.168.122.1'
          'client.fqdn': {}
      .chain()
      .service 'test', 'chrony', (service) ->
        array_get(service.instances, (instance) -> instance.node.id is 'server.fqdn')
        .options.config.should.eql """
          allow 192.168/16
          local stratum 10
          manual
          """
        array_get service.instances, (instance) -> instance.node.id is 'client.fqdn'
        .options.config.should.eql """
          server 192.168.122.1 iburst
          """
