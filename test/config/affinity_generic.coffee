
import fs from 'node:fs/promises'
import nikita from 'nikita'
import normalize from 'masson/config/normalize'
import affinity from 'masson/config/affinities'
import store from 'masson/config/store'

describe 'affinity generic', ->
  
  describe 'normalize', ->
  
    it 'minimal', ->
      affinity.handlers.generic.normalize
        match: 'all'
        values: []
      .should.eql
        type: 'generic'
        match: 'all'
        values: []
          
    it 'validate properties', ->
      ( ->
        affinity.handlers.generic.normalize
          match: 'all'
      ).should.throw 'Required Property: "values" not found'
      ( ->
        affinity.handlers.generic.normalize
          match: 'all'
          values: {}
      ).should.throw 'Invalid Property: "values" not an array'
      
    it 'multiple affinities', ->
      affinity.handlers.generic.normalize
        match: 'all', values:[
          type: 'tags', values: 'role': 'master'
        ,
          type: 'nodes', match: 'any', values: ['a.fqdn', 'b.fqdn']
        ]
      .should.eql
        type: 'generic', match: 'all', values: [
          type: 'tags', values: 'role': values: 'master': true
        ,
          type: 'nodes', match: 'any', values: 'a.fqdn': true, 'b.fqdn': true
        ]

  describe 'resolve', ->

    it 'match all', ->
      nikita
        $tmpdir: true
      , ({metadata: {tmpdir}}) ->
        await fs.writeFile "#{tmpdir}/a.json", JSON.stringify {}
        store await normalize
          clusters: 'cluster_a': services: 'service_a':
            module: "#{tmpdir}/a.json"
            affinity:
              match: 'all'
              values: [
                type: 'tags'
                values: 'role': 'master'
              ,
                type: 'nodes'
                match: 'any'
                values: ['a.fqdn', 'b.fqdn']
              ]
          nodes:
            'a.fqdn': tags: 'env': 'prod', 'role': ['master', 'worker']
            'b.fqdn': tags: 'env': 'prod', 'role': 'client'
            'c.fqdn': tags: 'env': 'dev', 'role': 'client'
            'd.fqdn': tags: 'env': 'dev', 'role': 'master'
        .chain()
        .service 'cluster_a', 'service_a', (service) ->
          service.instances
          .map (instance) -> instance.node.id
          .should.eql ['a.fqdn']

    it 'match any', ->
      nikita
        $tmpdir: true
      , ({metadata: {tmpdir}}) ->
        await fs.writeFile "#{tmpdir}/a.json", JSON.stringify {}
        store await normalize
          clusters: 'cluster_a': services: 'service_a':
            module: "#{tmpdir}/a.json"
            affinity:
              match: 'any'
              values: [
                type: 'tags'
                values: 'role': 'master'
              ,
                type: 'nodes'
                match: 'any'
                values: ['a.fqdn', 'b.fqdn']
              ]
          nodes:
            'a.fqdn': tags: 'env': 'prod', 'role': ['master', 'worker']
            'b.fqdn': tags: 'env': 'prod', 'role': 'client'
            'c.fqdn': tags: 'env': 'dev', 'role': 'client'
            'd.fqdn': tags: 'env': 'dev', 'role': 'master'
        .chain()
        .service 'cluster_a', 'service_a', (service) ->
          service.instances
          .map (instance) -> instance.node.id
          .should.eql ['a.fqdn', 'b.fqdn', 'd.fqdn']
  
