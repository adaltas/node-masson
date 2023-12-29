
import fs from 'node:fs/promises'
import nikita from 'nikita'
import normalize from 'masson/config/normalize'
import store from 'masson/config/store'

describe 'normalize services', ->
  
  it 'value is true', ->
    nikita
      $tmpdir: true
    , ({metadata: {tmpdir}}) ->
      await fs.writeFile "#{tmpdir}/a.json", JSON.stringify {}
      store await normalize
        clusters:
          'cluster_a':
            services:
              "#{tmpdir}/a.json": true
      .service 'cluster_a', "#{tmpdir}/a.json"
      .should.eql
        id: "#{tmpdir}/a.json"
        cluster: 'cluster_a'
        module: "#{tmpdir}/a.json"
        affinity: []
        deps: {}
        commands: {}
        instances: []
        nodes: {}
        
  it 'module is string', ->
    nikita
      $tmpdir: true
    , ({metadata: {tmpdir}}) ->
      await fs.writeFile "#{tmpdir}/a.json", JSON.stringify {}
      store await normalize
        clusters:
          'cluster_a':
            services:
              'service_a':
                module: "#{tmpdir}/a.json"
      .service 'cluster_a', 'service_a'
      .should.eql
        id: 'service_a'
        cluster: 'cluster_a'
        module: "#{tmpdir}/a.json"
        affinity: []
        deps: {}
        commands: {}
        instances: []
        nodes: {}
  
