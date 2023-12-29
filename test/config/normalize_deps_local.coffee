
import nikita from 'nikita'
import normalize from 'masson/config/normalize'
import store from 'masson/config/store'

describe 'normalize deps local', ->
  
  it 'local with no match', ->
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
            deps: 'my_dep_a': module: "#{tmpdir}/dep_a.json", local: true
            configure: (service) ->
              services.push service
        nodes:
          'a.fqdn': ip: '10.10.10.1'
          'b.fqdn': ip: '10.10.10.2'
          'c.fqdn': ip: '10.10.10.3'
      services.map (service) ->
        service.deps.my_dep_a
      .should.eql [null, null]
      
  it 'local with multiple matches', ->
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
            affinity: type: 'nodes', match: 'any', values: ['a.fqdn', 'b.fqdn', 'c.fqdn']
            options: 'key': 'value'
          'service_a':
            module: "#{tmpdir}/a.json"
            affinity: type: 'nodes', match: 'any', values: ['a.fqdn', 'c.fqdn']
            deps: 'my_dep_a': module: "#{tmpdir}/dep_a.json", local: true
            configure: (service) ->
              services.push service
        nodes:
          'a.fqdn': ip: '10.10.10.1'
          'b.fqdn': ip: '10.10.10.2'
          'c.fqdn': ip: '10.10.10.3'
      services.map (service) ->
        service.deps.my_dep_a.node.id
      .should.eql ['a.fqdn', 'c.fqdn']
      
  it.skip 'local but defined elsewhere', ->
    nikita
      $tmpdir: true
    , ({metadata: {tmpdir}}) ->
      # Not yet implemented, proposal as for now
      await @file.json target: "#{tmpdir}/dep_a.json", content: {}
      await @file.json target: "#{tmpdir}/a.json", content: {}
      services = []
      await normalize
        clusters: 'cluster_a': services:
          'dep_a':
            module: "#{tmpdir}/dep_a.json"
            affinity: type: 'nodes', match: 'any', values: ['b.fqdn']
            options: 'key': 'value'
          'service_a':
            module: "#{tmpdir}/a.json"
            affinity: type: 'nodes', match: 'any', values: ['a.fqdn', 'c.fqdn']
            deps: 'my_dep_a': module: "#{tmpdir}/dep_a.json", local: true
            configure: (service) ->
              services.push service
        nodes:
          'a.fqdn': ip: '10.10.10.1'
          'b.fqdn': ip: '10.10.10.2'
          'c.fqdn': ip: '10.10.10.3'
      services.map (service) ->
        service.deps.my_dep_a.id.should.eql 'dep_a'
        service.deps.my_dep_a.node.id
      .should.eql ['a.fqdn', 'c.fqdn']
      
