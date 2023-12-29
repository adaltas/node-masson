
import nikita from 'nikita'
import normalize from 'masson/config/normalize'
import store from 'masson/config/store'

describe 'normalize deps single', ->
  
  it 'single match dep on another node', ->
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
            deps: 'my_dep_a': module: "#{tmpdir}/dep_a.json", single: true
            configure: (service) ->
              services.push service
        nodes:
          'a.fqdn': ip: '10.10.10.1'
          'b.fqdn': ip: '10.10.10.2'
          'c.fqdn': ip: '10.10.10.3'
      services.map (service) ->
        service.deps.my_dep_a.node.id
      .should.eql ['b.fqdn', 'b.fqdn']
      
  it 'single is compatible with local', ->
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
            affinity: type: 'nodes', match: 'any', values: ['a.fqdn', 'b.fqdn']
            deps: 'my_dep_a': module: "#{tmpdir}/dep_a.json", single: true, local: true
            configure: (service) ->
              services.push service
        nodes:
          'a.fqdn': ip: '10.10.10.1'
          'b.fqdn': ip: '10.10.10.2'
          'c.fqdn': ip: '10.10.10.3'
      services.map (service) ->
        if service.deps.my_dep_a
        then service.deps.my_dep_a.node.id
        else null
      .should.eql [null, 'b.fqdn']

  it 'dependency not loaded', ->
    nikita
      $tmpdir: true
    , ({metadata: {tmpdir}}) ->
      await @file.json target: "#{tmpdir}/dep_a.json", content: {}
      await @file.json target: "#{tmpdir}/a.json", content: {}
      await normalize
        clusters: 'cluster_a': services:
          'service_a':
            module: "#{tmpdir}/a.json"
            affinity: type: 'nodes', match: 'any', values: ['a.fqdn', 'b.fqdn']
            deps: 'my_dep_a': module: "#{tmpdir}/dep_a.json", single: true
        nodes:
          'a.fqdn': ip: '10.10.10.1'
        'b.fqdn': ip: '10.10.10.2'
      
  it 'single throw if multiple', ->
    nikita
      $tmpdir: true
    , ({metadata: {tmpdir}}) ->
      await @file.json target: "#{tmpdir}/dep_a.json", content: {}
      await @file.json target: "#{tmpdir}/a.json", content: {}
      await normalize
        clusters: 'cluster_a': services:
          'dep_a':
            module: "#{tmpdir}/dep_a.json"
            affinity: type: 'nodes', match: 'any', values: ['a.fqdn', 'b.fqdn', 'c.fqdn']
            options: 'key': 'value'
          'service_a':
            module: "#{tmpdir}/a.json"
            affinity: type: 'nodes', match: 'any', values: ['a.fqdn', 'c.fqdn']
            deps: 'my_dep_a': module: "#{tmpdir}/dep_a.json", single: true
        nodes:
          'a.fqdn': ip: '10.10.10.1'
          'b.fqdn': ip: '10.10.10.2'
          'c.fqdn': ip: '10.10.10.3'
      .should.be.rejectedWith 'Invalid Option: single only apply to 1 dependencies, found 3'
