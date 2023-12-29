
import nikita from 'nikita'
import normalize from 'masson/config/normalize'
import store from 'masson/config/store'

describe 'normalize deps auto', ->
  
  it 'deps is automatically registered if not defined', ->
    nikita
      $tmpdir: true
    , ({metadata: {tmpdir}}) ->
      await @file.json target: "#{tmpdir}/dep_a.json", content: {}
      await @file.json target: "#{tmpdir}/a.json", content: {}
      services = []
      store await normalize
        clusters: 'cluster_a': services:
          'service_a':
            module: "#{tmpdir}/a.json"
            affinity: type: 'nodes', match: 'any', values: ['a.fqdn', 'c.fqdn']
            deps: 'my_dep_a': module: "#{tmpdir}/dep_a.json", local: true, auto: true
            configure: (service) ->
              services.push service
        nodes:
          'a.fqdn': ip: '10.10.10.1'
          'b.fqdn': ip: '10.10.10.2'
          'c.fqdn': ip: '10.10.10.3'
      .chain()
      .cluster 'cluster_a', (cluster) ->
        Object.keys(cluster.services).should.eql [ 'service_a', "#{tmpdir}/dep_a.json" ]
      .service 'cluster_a', "service_a", (service) ->
        service.deps.my_dep_a.should.eql
          module: "#{tmpdir}/dep_a.json"
          local: true
          auto: true
          cluster: 'cluster_a'
          service: "#{tmpdir}/dep_a.json"
          disabled: false
      .service 'cluster_a', "#{tmpdir}/dep_a.json", (service) ->
        # Dependency should now be registered
        service.id.should.eql "#{tmpdir}/dep_a.json"
        service.module.should.eql "#{tmpdir}/dep_a.json"
        service.commands.should.eql {}
        # Affinity must be defined
        service.affinity.should.eql [
          type: 'nodes'
          match: 'any'
          values: 'a.fqdn': true, 'c.fqdn': true
        ]
        # Affinity must be resolved
        service.instances.map((instance) -> instance.node.id).should.eql ['a.fqdn', 'c.fqdn']
  
  it 'load the module', ->
    nikita
      $tmpdir: true
    , ({metadata: {tmpdir}}) ->
      await @file.json target: "#{tmpdir}/dep_a.json", content:
        commands:
          'install': 'some/module/install'
      await @file.json target: "#{tmpdir}/a.json", content: {}
      services = []
      s = store await normalize
        clusters: 'cluster_a': services:
          'service_a':
            module: "#{tmpdir}/a.json"
            affinity: type: 'nodes', match: 'any', values: 'a.fqdn'
            deps: 'my_dep_a': module: "#{tmpdir}/dep_a.json", local: true, auto: true
            configure: (service) ->
              services.push service
        nodes:
          'a.fqdn': ip: '10.10.10.1'
      .chain()
      .service 'cluster_a', "#{tmpdir}/dep_a.json", (service) ->
        service.commands.install.should.eql ['some/module/install' ]
  
  it 'load the module recusively', ->
    nikita
      $tmpdir: true
    , ({metadata: {tmpdir}}) ->
      await @file.json target: "#{tmpdir}/dep_b.json", content:  {}
      await @file.json target: "#{tmpdir}/dep_a.json", content:
        deps:
          'my_dep_b': module: "#{tmpdir}/dep_b.json", local: true, auto: true
      await @file.json target: "#{tmpdir}/a.json", content: {}
      services = []
      s = store await normalize
        clusters: 'cluster_a': services:
          'service_a':
            module: "#{tmpdir}/a.json"
            affinity: type: 'nodes', match: 'any', values: 'a.fqdn'
            deps: 'my_dep_a': module: "#{tmpdir}/dep_a.json", local: true, auto: true
            configure: (service) ->
              services.push service
        nodes:
          'a.fqdn': ip: '10.10.10.1'
      .chain()
      .service 'cluster_a', "#{tmpdir}/dep_b.json", (service) ->
        service.id.should.eql "#{tmpdir}/dep_b.json"
        service.module.should.eql "#{tmpdir}/dep_b.json"
        service.cluster.should.eql 'cluster_a'
        service.affinity.should.eql [ type: 'nodes', match: 'any', values: "a.fqdn": true ]
  
  it 'deps is defined but dont match', ->
    nikita
      $tmpdir: true
    , ({metadata: {tmpdir}}) ->
      await @file.json target: "#{tmpdir}/dep_a.json", content: {}
      await @file.json target: "#{tmpdir}/a.json", content: {}
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
            deps: 'my_dep_a': module: "#{tmpdir}/dep_a.json", local: true, auto: true
            configure: (service) ->
              services.push service
        nodes:
          'a.fqdn': ip: '10.10.10.1'
          'b.fqdn': ip: '10.10.10.2'
          'c.fqdn': ip: '10.10.10.3'
      services.map (service) ->
        service.deps.my_dep_a.node.id
      .should.eql ['a.fqdn', 'c.fqdn']
