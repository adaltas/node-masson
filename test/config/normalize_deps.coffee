
import nikita from 'nikita'
import normalize from 'masson/config/normalize'
import store from 'masson/config/store'

describe 'normalize deps', ->
  
  it 'ensure module is defined', ->
    nikita
      $tmpdir: true
    , ({metadata: {tmpdir}}) ->
      await @file.json target: "#{tmpdir}/a.json", content:
        deps: 'dep_a_1': {}
      normalize
        clusters: 'cluster_a': services: 'service_a': module: "#{tmpdir}/a.json"
      .should.be.rejectedWith 'Unidentified Dependency: require module or service property'
  
  it 'discover and resolve service id based on module', ->
    nikita
      $tmpdir: true
    , ({metadata: {tmpdir}}) ->
      await @file.json target: "#{tmpdir}/dep_a.json", content: {}
      await @file.json target: "#{tmpdir}/a.json", content:
        deps: 'dep_a': module: "#{tmpdir}/dep_a.json"
      store await normalize
        clusters: 'cluster_a': services:
          'dep_a_id': module: "#{tmpdir}/dep_a.json"
          'service_a': module: "#{tmpdir}/a.json"
      .service 'cluster_a', 'service_a'
      .deps['dep_a']
      .should.eql
        cluster: 'cluster_a', service: 'dep_a_id', module: "#{tmpdir}/dep_a.json", disabled: false

  it 'resolve base on service id converted to module', ->
    nikita
      $tmpdir: true
    , ({metadata: {tmpdir}}) ->
      await @file.json target: "#{tmpdir}/dep_a.json", content: {}
      await @file.json target: "#{tmpdir}/a.json", content:
        deps: 'dep_a': "#{tmpdir}/dep_a.json"
      store await normalize
        clusters: 'cluster_a': services:
          "#{tmpdir}/dep_a.json": true
          'service_a': module: "#{tmpdir}/a.json"
      .service 'cluster_a', "#{tmpdir}/dep_a.json"
      .should.eql
        id: "#{tmpdir}/dep_a.json"
        cluster: 'cluster_a'
        module: "#{tmpdir}/dep_a.json"
        affinity: []
        deps: {}
        commands: {}
        instances: []
        nodes: {}
  
  it 'load and merge module', ->
    nikita
      $tmpdir: true
    , ({metadata: {tmpdir}}) ->
      await @file.json target: "#{tmpdir}/dep_a.json", content:
        my_property: true
      await @file.json target: "#{tmpdir}/a.json", content:
        deps: 'dep_a': "#{tmpdir}/dep_a.json"
      store await normalize
        clusters: 'cluster_a': services:
          "#{tmpdir}/dep_a.json": true
          'service_a': module: "#{tmpdir}/a.json"
      .service 'cluster_a', "#{tmpdir}/dep_a.json"
      .my_property
      .should.be.true()
  
  it 'validate service reference with multiple module match', ->
    nikita
      $tmpdir: true
    , ({metadata: {tmpdir}}) ->
      await @file.json target: "#{tmpdir}/dep_a.json", content: {}
      await @file.json target: "#{tmpdir}/a.json", content: {}
      normalize
        clusters: 'cluster_a': services:
          'dep_a_1': module: "#{tmpdir}/dep_a.json"
          'dep_a_2': module: "#{tmpdir}/dep_a.json"
          'service_a':
            module: "#{tmpdir}/a.json"
            deps: 'dep_a': module: "#{tmpdir}/dep_a.json"
      .should.be.rejectedWith "Invalid Service Reference: multiple matches for module \"#{tmpdir}/dep_a.json\" in cluster \"cluster_a\""
