
import fs from 'node:fs/promises'
import nikita from 'nikita'
import normalize from 'masson/config/normalize'
import store from 'masson/config/store'

describe 'normalize service affinity', ->
    
  it 'no affinity', ->
    nikita
      $tmpdir: true
    , ({metadata: {tmpdir}}) ->
      await fs.writeFile "#{tmpdir}/a.json", JSON.stringify {}
      store await normalize
        clusters: 'cluster_a': services:
          'service_a': module: "#{tmpdir}/a.json"
        nodes:
          'a.fqdn': ip: '10.10.10.1'
          'b.fqdn': ip: '10.10.10.2'
      .chain()
      .service 'cluster_a', 'service_a', (service) ->
        service.nodes.should.eql {}
      .node 'a.fqdn', (node) ->
        node.services.should.eql []
      
  it 'is enriched from cluster services', ->
    nikita
      $tmpdir: true
    , ({metadata: {tmpdir}}) ->
      await fs.writeFile "#{tmpdir}/a.json", JSON.stringify {}
      store await normalize
        clusters: 'cluster_a': services:
          'service_a':
            module: "#{tmpdir}/a.json"
            affinity:
              type: 'nodes'
              values: 'b.fqdn'
        nodes:
          'a.fqdn': ip: '10.10.10.1'
          'b.fqdn': ip: '10.10.10.2'
      .chain()
      .service 'cluster_a', 'service_a', (service) ->
        service.instances
        .map (instance) -> instance.node.id
        .should.eql ['b.fqdn']
      .node 'b.fqdn', (node) ->
        node.services.should.eql [
          cluster: 'cluster_a', service: 'service_a', module: "#{tmpdir}/a.json"
        ]
  
