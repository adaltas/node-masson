
normalize = require '../../../lib/config/normalize'
store = require '../../../lib/config/store'

describe 'configure', ->
  
  it 'merge options hosts and hosts_auto', ->
    store normalize
      clusters: 'test': services: 'masson/core/network':
        affinity: type: 'tags', values: 'env': 'dev'
        options:
          hosts_auto: true
          hosts: '10.10.10.10': 'repos.ryba ryba'
      nodes:
        'node_01.fqdn': ip: '10.10.10.11', tags: 'env': 'dev'
        'node_02.fqdn': ip: '10.10.10.12', tags: 'env': 'dev'
    .chain()
    .service 'test', 'masson/core/network', (service) ->
      Object.values(service.nodes)
      .map (node) ->
        node.options.hosts.should.eql
          '10.10.10.10': 'repos.ryba ryba'
          '10.10.10.11': 'node_01.fqdn node_01'
          '10.10.10.12': 'node_02.fqdn node_02'
        node.id
      .should.eql ['node_01.fqdn', 'node_02.fqdn']
