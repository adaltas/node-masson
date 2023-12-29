
import fs from 'node:fs/promises'
import nikita from 'nikita'
import normalize from 'masson/config/normalize'
import store from 'masson/config/store'

describe 'normalize service configure', ->
  
  it 'inject node and instances', ->
    nikita
      $tmpdir: true
    , ({metadata: {tmpdir}}) ->
      await fs.writeFile "#{tmpdir}/a.json", JSON.stringify {}
      services = []
      await normalize
        clusters: 'cluster_a': services:
          'service_a':
            module: "#{tmpdir}/a.json"
            affinity: type: 'nodes', match: 'any', values: ['a.fqdn', 'c.fqdn']
            configure: (service) ->
              services.push service
        nodes:
          'a.fqdn': ip: '10.10.10.1'
          'b.fqdn': ip: '10.10.10.2'
          'c.fqdn': ip: '10.10.10.3'
      services
      .map (service) ->
        service.instances.length.should.eql 2
        # Test node
        node_id: service.node.id
        # Test nodes
        instance_node_ids: service.instances.map (instance) -> instance.node.id
      .should.eql [
        node_id: 'a.fqdn'
        instance_node_ids: ['a.fqdn', 'c.fqdn']
      ,
        node_id: 'c.fqdn'
        instance_node_ids: ['a.fqdn', 'c.fqdn']
      ]

  it 'inject deps using module discovery', ->
    nikita
      $tmpdir: true
    , ({metadata: {tmpdir}}) ->
      await fs.writeFile "#{tmpdir}/dep_a.json", JSON.stringify {}
      await fs.writeFile "#{tmpdir}/a.json", JSON.stringify {}
      services = []
      await normalize
        clusters: 'cluster_a': services:
          'dep_a':
            module: "#{tmpdir}/dep_a.json"
            affinity: type: 'nodes', values: 'b.fqdn'
            options: 'key': 'value'
          'service_a':
            module: "#{tmpdir}/a.json"
            affinity: type: 'nodes', match: 'any', values: ['a.fqdn', 'c.fqdn']
            deps:
              'dep_defined': module: "#{tmpdir}/dep_a.json"
              'dep_undefined': module: "#{tmpdir}/dep_b.json"
            configure: (service) ->
              services.push service
        nodes:
          'a.fqdn': ip: '10.10.10.1'
          'b.fqdn': ip: '10.10.10.2'
          'c.fqdn': ip: '10.10.10.3'
      services.map (service) ->
        (service.deps.dep_undefined is undefined).should.be.true()
        service.deps.dep_defined.length.should.eql 1
        [dep_defined] = service.deps.dep_defined
        # Object.values(dep_defined.nodes).length.should.eql 1
        # Test deps node
        dep_a_cluster: dep_defined.cluster
        dep_a_service: dep_defined.service
        dep_a_node_id: dep_defined.node.id
        # Test deps nodes
        # dep_a_nodes_0_id: Object.values(dep_defined.nodes)[0].id
        # Test deps options
        dep_a_options_key: dep_defined.options.key
      .should.eql [
        dep_a_cluster: 'cluster_a'
        dep_a_service: 'dep_a'
        dep_a_node_id: 'b.fqdn'
        # dep_a_nodes_0_id: 'b.fqdn'
        dep_a_options_key: 'value'
      ,
        dep_a_cluster: 'cluster_a'
        dep_a_service: 'dep_a'
        dep_a_node_id: 'b.fqdn'
        # dep_a_nodes_0_id: 'b.fqdn'
        dep_a_options_key: 'value'
      ]

  it 'inject deps using module discovery', ->
    nikita
      $tmpdir: true
    , ({metadata: {tmpdir}}) ->
      await fs.writeFile "#{tmpdir}/a.json", JSON.stringify {}
      services = []
      await normalize
        clusters: 'cluster_a': services:
          'service_a':
            module: "#{tmpdir}/a.json"
            affinity: type: 'nodes', match: 'any', values: ['a.fqdn', 'c.fqdn']
            deps:
              'dep_self': module: "#{tmpdir}/a.json"
            configure: (service) ->
              services.push service
              service.options.a_key = 'a value'
        nodes:
          'a.fqdn': ip: '10.10.10.1'
          'b.fqdn': ip: '10.10.10.2'
          'c.fqdn': ip: '10.10.10.3'
      services.length.should.eql 2
      services.map (service) ->
        service.deps.dep_self.map (dep_self) ->
          dep_self.id is 'service_a'
          dep_self.options.a_key = 'a value'

  it 'options is independantly cloned between nodes', ->
    nikita
      $tmpdir: true
    , ({metadata: {tmpdir}}) ->
      await fs.writeFile "#{tmpdir}/a.json", JSON.stringify {}
      services = []
      store await normalize
        clusters: 'cluster_a': services:
          'service_a':
            module: "#{tmpdir}/a.json"
            affinity: type: 'nodes', match: 'any', values: ['a.fqdn', 'c.fqdn']
            deps:
              'dep_self': service: 'service_a'
            configure: (service) ->
              service.options.test = service.node.fqdn
        nodes:
          'a.fqdn': ip: '10.10.10.1'
          'b.fqdn': ip: '10.10.10.2'
          'c.fqdn': ip: '10.10.10.3'
      .chain()
      .service 'cluster_a', 'service_a', (service) ->
        service.instances.length.should.eql 2
        service.instances
        .map (instance) -> instance.options
        .should.eql [
          { test: 'a.fqdn' }
          { test: 'c.fqdn' }
        ]

  it 'self enrich other nodes', ->
    nikita
      $tmpdir: true
    , ({metadata: {tmpdir}}) ->
      await fs.writeFile "#{tmpdir}/a.json", JSON.stringify {}
      services = []
      store await normalize
        clusters: 'cluster_a': services:
          'service_a':
            module: "#{tmpdir}/a.json"
            affinity: type: 'nodes', match: 'any', values: ['a.fqdn', 'c.fqdn']
            deps:
              'dep_self': service: 'service_a'
            configure: (service) ->
              service.deps.dep_self.length.should.eql 2
              for srv in service.deps.dep_self
                srv.options.test ?= []
                srv.options.test.push service.node.fqdn
        nodes:
          'a.fqdn': ip: '10.10.10.1'
          'b.fqdn': ip: '10.10.10.2'
          'c.fqdn': ip: '10.10.10.3'
      .chain()
      .service 'cluster_a', 'service_a', (service) ->
        service.instances
        .map (instance) -> instance.options
        .should.eql [
          { test: ['a.fqdn', 'c.fqdn'] }
          { test: ['a.fqdn', 'c.fqdn'] }
        ]
