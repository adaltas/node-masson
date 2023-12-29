
import fs from 'node:fs/promises'
import nikita from 'nikita'
import normalize from 'masson/config/normalize'
import store from 'masson/config/store'

describe 'normalize nodes services', ->
          
  it 'must reference existing service', ->
    normalize
      clusters: 'cluster_a': services: {}
      nodes:
        'a.fqdn': ip: '10.10.10.1'
        'b.fqdn': ip: '10.10.10.2', services: [
          cluster: 'cluster_a', service: 'service_a', options: a_key: 'a value'
        ]
    .should.be.rejectedWith 'Node Invalid Service: node "b.fqdn" references missing service "service_a" in cluster "cluster_a"'

  it 'can be declared as an object', ->
    nikita
      $tmpdir: true
    , ({metadata: {tmpdir}}) ->
      await fs.writeFile "#{tmpdir}/a.json", JSON.stringify {}
      store await normalize
        clusters: 'cluster_a': services:
          'service_a':
            module: "#{tmpdir}/a.json"
            affinity: type: 'nodes', values: 'b.fqdn'
        nodes:
          'a.fqdn': ip: '10.10.10.1'
          'b.fqdn': ip: '10.10.10.2', services:
            'cluster_a:service_a': 'a_key': 'a value'
      .chain()
      .node 'b.fqdn', (node) ->
        node.services.length is 1
        node.services[0].should.eql
          cluster: 'cluster_a'
          service: 'service_a'
          module: "#{tmpdir}/a.json"
          options: 'a_key': 'a value'

  it 'merge options', ->
    nikita
      $tmpdir: true
    , ({metadata: {tmpdir}}) ->
      await fs.writeFile "#{tmpdir}/a.json", JSON.stringify {}
      store await normalize
        clusters: 'cluster_a': services:
          'service_a':
            module: "#{tmpdir}/a.json"
            affinity: type: 'nodes', values: 'b.fqdn'
            options: overwritten_key: 'a value'
        nodes:
          'a.fqdn': ip: '10.10.10.1'
          'b.fqdn': ip: '10.10.10.2', services: [
            cluster: 'cluster_a', service: 'service_a', options: overwritten_key: 'an overwritten value'
          ]
      .service 'cluster_a', 'service_a'
      .instances
      .filter((instance) -> instance.node.id is 'b.fqdn')[0]
      .options.overwritten_key.should.eql 'an overwritten value'

  it 'contain cluster, service and module', ->
    nikita
      $tmpdir: true
    , ({metadata: {tmpdir}}) ->
      await fs.writeFile "#{tmpdir}/dep_a.json", JSON.stringify {}
      await fs.writeFile "#{tmpdir}/dep_b.json", JSON.stringify {}
      await fs.writeFile "#{tmpdir}/a.json", JSON.stringify {}
      store await normalize
        clusters: 'cluster_a': services:
          'dep_a':
            module: "#{tmpdir}/dep_a.json"
            affinity: type: 'nodes', values: 'a.fqdn'
          'service_a':
            module: "#{tmpdir}/a.json"
            deps:
              'my_dep_a': module: "#{tmpdir}/dep_a.json"
            affinity: type: 'nodes', values: 'a.fqdn'
        nodes:
          'a.fqdn': services: [
            cluster: 'cluster_a', service: 'service_a'
          ]
      .node 'a.fqdn'
      .services.should.eql [
        cluster: 'cluster_a', service: 'dep_a', module: "#{tmpdir}/dep_a.json"
      ,
        cluster: 'cluster_a', service: 'service_a', module: "#{tmpdir}/a.json"
      ]

  it 're-order services based on graph', ->
    nikita
      $tmpdir: true
    , ({metadata: {tmpdir}}) ->
      await fs.writeFile "#{tmpdir}/dep_a.json", JSON.stringify {}
      await fs.writeFile "#{tmpdir}/dep_b.json", JSON.stringify {}
      await fs.writeFile "#{tmpdir}/a.json", JSON.stringify {}
      store await normalize
        clusters: 'cluster_a': services:
          'dep_a':
            module: "#{tmpdir}/dep_a.json"
            affinity: type: 'nodes', values: 'b.fqdn'
          'dep_b':
            module: "#{tmpdir}/dep_b.json"
            deps: 'my_dep_a': module: "#{tmpdir}/dep_a.json"
          'service_a':
            module: "#{tmpdir}/a.json"
            deps:
              'my_dep_a': module: "#{tmpdir}/dep_a.json"
              'my_dep_b': module: "#{tmpdir}/dep_b.json", local: true, auto: true
            affinity: type: 'nodes', values: 'b.fqdn'
        nodes:
          'a.fqdn': ip: '10.10.10.1'
          'b.fqdn': ip: '10.10.10.2', services: [
            cluster: 'cluster_a', service: 'service_a'
          ]
      .node 'b.fqdn'
      .services.should.eql [
        cluster: 'cluster_a', service: 'dep_a', module: "#{tmpdir}/dep_a.json"
      ,
        cluster: 'cluster_a', service: 'dep_b', module: "#{tmpdir}/dep_b.json"
      ,
        cluster: 'cluster_a', service: 'service_a', module: "#{tmpdir}/a.json"
      ]
