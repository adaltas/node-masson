
import nikita from 'nikita'
import normalize from 'masson/config/normalize'
import store from 'masson/config/store'

describe 'normalize deps required', ->

  it 'validate cluster reference when false', ->
    nikita
      $tmpdir: true
    , ({metadata: {tmpdir}}) ->
      await @file.json target: "#{tmpdir}/a.json", content:
        deps: 'dep_a': cluster: 'anywhere', service: 'anything', module: "#{tmpdir}/dep_a.json", required: false
      await store await normalize
        clusters: 'cluster_a': services: 'service_a': module: "#{tmpdir}/a.json"
      .service 'cluster_a', 'service_a'
      .deps
      .should.eql
        'dep_a': cluster: 'anywhere', service: 'anything', module: "#{tmpdir}/dep_a.json", required: false, disabled: true
    
  it 'validate cluster reference, when true', ->
    nikita
      $tmpdir: true
    , ({metadata: {tmpdir}}) ->
      await @file.json target: "#{tmpdir}/a.json", content:
        deps: 'dep_a': cluster: 'cluster_b', service: 'anything', module: "#{tmpdir}/dep_a.json", required: true
      await normalize
        clusters: 'cluster_a': services: 'service_a': module: "#{tmpdir}/a.json"
      .should.be.rejectedWith 'Invalid Cluster Reference: cluster "cluster_b" is not defined'
  
  it 'validate service reference, when false', ->
    nikita
      $tmpdir: true
    , ({metadata: {tmpdir}}) ->
      await @file.json target: "#{tmpdir}/a.json", content:
        deps: 'dep_a': service: 'anything', module: "#{tmpdir}/dep_a.json", required: false
      store await normalize
        clusters: 'cluster_a': services: 'service_a': module: "#{tmpdir}/a.json"
      .service 'cluster_a', 'service_a'
      .deps
      .should.eql
        'dep_a': cluster: 'cluster_a', service: 'anything', module: "#{tmpdir}/dep_a.json", required: false, disabled: true
  
  it 'validate service reference based on service id, when true', ->
    nikita
      $tmpdir: true
    , ({metadata: {tmpdir}}) ->
      await @file.json target: "#{tmpdir}/a.json", content: {}
      await normalize
        clusters: 'cluster_a': services: 'service_a':
          module: "#{tmpdir}/a.json"
          deps: 'dep_a': service: 'dep_a', module: "#{tmpdir}/dep_a.json", required: true
      .should.be.rejectedWith "Required Dependency: unsatisfied dependency \"dep_a\" in service \"cluster_a:service_a\", service \"dep_a\" in cluster \"cluster_a\" is not defined"
      # await normalize
      #   clusters: 'cluster_a': services: 'service_a':
      #     module: "#{tmpdir}/a.json"
      #     deps: 'dep_a': service: 'dep_a', module: "#{tmpdir}/dep_a.json", required: true
      # .should.be.rejectedWith "Required Dependency: unsatisfied dependency \"dep_a\" in service \"cluster_a:service_a\", service \"dep_a\" in cluster \"cluster_a\" is not defined"
      # await Promise.reject(Error 'hum')
      # try
      #   await normalize
      #     clusters: 'cluster_a': services: 'service_a':
      #       module: "#{tmpdir}/a.json"
      #       deps: 'dep_a': service: 'dep_a', module: "#{tmpdir}/dep_a.json", required: true
      # catch err
      #   console.log('!!!!!err', typeof err, err)
      # ( ->
      #   store await normalize
      #     clusters: 'cluster_a': services: 'service_a':
      #       module: "#{tmpdir}/a.json"
      #       deps: 'dep_a': service: 'dep_a', module: "#{tmpdir}/dep_a.json", required: true
      #   .service 'cluster_a', 'service_a'
      # ).should.throw "Required Dependency: unsatisfied dependency \"dep_a\" in service \"cluster_a:service_a\", service \"dep_a\" in cluster \"cluster_a\" is not defined"

  it 'validate service reference based on module, when true', ->
    nikita
      $tmpdir: true
    , ({metadata: {tmpdir}}) ->
      await @file.json target: "#{tmpdir}/a.json", content: {}
      await normalize
        clusters: 'cluster_a': services: 'service_a':
          module: "#{tmpdir}/a.json"
          deps: 'dep_a': module: "#{tmpdir}/dep_a.json", required: true
      .should.be.rejectedWith "Required Dependency: unsatisfied dependency \"dep_a\" in service \"cluster_a:service_a\", module \"#{tmpdir}/dep_a.json\" in cluster \"cluster_a\" is not defined"

  it 'validate local with valid config', ->
    nikita
      $tmpdir: true
    , ({metadata: {tmpdir}}) ->
      await @file.json target: "#{tmpdir}/dep_a.json", content: {}
      await @file.json target: "#{tmpdir}/a.json", content: {}
      # Valid
      store await normalize
        clusters: 'cluster_a': services:
          'dep_a':
            module: "#{tmpdir}/dep_a.json"
            affinity: type: 'nodes', match: 'any', values: ['a.fqdn', 'b.fqdn', 'c.fqdn']
          'service_a':
            module: "#{tmpdir}/a.json"
            affinity: type: 'nodes', match: 'any', values: 'b.fqdn'
            deps: 'dep_a': module: "#{tmpdir}/dep_a.json", local: true, required: true
        nodes:
          'a.fqdn': {}
          'b.fqdn': {}
          'c.fqdn': {}
      .service 'cluster_a', 'service_a'

  it 'validate local with invalid config', ->
    nikita
      $tmpdir: true
    , ({metadata: {tmpdir}}) ->
      await @file.json target: "#{tmpdir}/dep_a.json", content: {}
      await @file.json target: "#{tmpdir}/a.json", content: {}
      # Invalid
      await normalize
        clusters: 'cluster_a': services:
          'dep_a':
            module: "#{tmpdir}/dep_a.json"
            affinity: type: 'nodes', match: 'any', values: ['a.fqdn', 'c.fqdn']
          'service_a':
            module: "#{tmpdir}/a.json"
            affinity: type: 'nodes', match: 'any', values: 'b.fqdn'
            deps: 'dep_a': module: "#{tmpdir}/dep_a.json", local: true, required: true
        nodes:
          'a.fqdn': {}
          'b.fqdn': {}
          'c.fqdn': {}
      .should.be.rejectedWith 'Required Local Dependency: service "service_a" in cluster "cluster_a" require service "dep_a" in cluster "cluster_a" to be present on node b.fqdn'
