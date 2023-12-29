
import fs from 'node:fs/promises'
import nikita from 'nikita'
import normalize from 'masson/config/normalize'
import affinity from 'masson/config/affinities'
import store from 'masson/config/store'

describe 'affinity nodes', ->
  
  describe 'normalize', ->
  
    it 'values as string', ->
      affinity.handlers.nodes.normalize
        type: 'nodes', values: 'fqdn_a'
      .should.eql
        type: 'nodes', values: 'fqdn_a': true
            
    it 'values as array', ->
      affinity.handlers.nodes.normalize
        type: 'nodes', values: ['fqdn_a']
      .should.eql
        type: 'nodes', values: 'fqdn_a': true
            
    it 'values as object', ->
      affinity.handlers.nodes.normalize
        type: 'nodes', values: 'fqdn_a': true
      .should.eql
        type: 'nodes', values: 'fqdn_a': true
    
    it 'Required Option: match', ->
      ( ->
        affinity.handlers.nodes.normalize
          type: 'nodes', values: 'fqdn_a': true, 'fqdn_b': true
      ).should.throw 'Required Property: "match", when more than one values'

  describe 'resolve', ->
    
    it 'match single', ->
      nikita
        $tmpdir: true
      , ({metadata: {tmpdir}}) ->
        await fs.writeFile "#{tmpdir}/a.json", JSON.stringify {}
        s = store await normalize
          clusters: 'cluster_a': services: 'service_a':
            module: "#{tmpdir}/a.json"
            affinity: type: 'nodes', values: 'a.fqdn': true
          nodes:
            'a.fqdn': {}
            'b.fqdn': {}
        affinity.handlers.nodes.resolve s.config(),
          s.service('cluster_a', 'service_a').affinity[0]
        .should.eql ['a.fqdn']
        
    it 'match any', ->
      nikita
        $tmpdir: true
      , ({metadata: {tmpdir}}) ->
        await fs.writeFile "#{tmpdir}/a.json", JSON.stringify {}
        s = store await normalize
          clusters: 'cluster_a': services: 'service_a':
            module: "#{tmpdir}/a.json"
            affinity: type: 'nodes', match: 'any', values: 'a.fqdn': true, 'b.fqdn': true
          nodes:
            'a.fqdn': {}
            'b.fqdn': {}
        affinity.handlers.nodes.resolve s.config(),
          s.service('cluster_a', 'service_a').affinity[0]
        .should.eql ['a.fqdn', 'b.fqdn']
    
    it 'match none', ->
      nikita
        $tmpdir: true
      , ({metadata: {tmpdir}}) ->
        await fs.writeFile "#{tmpdir}/a.json", JSON.stringify {}
        s = store await normalize
          clusters: 'cluster_a': services: 'service_a':
            module: "#{tmpdir}/a.json"
            affinity: type: 'nodes', match: 'none', values: 'a.fqdn': true, 'c.fqdn': true
          nodes:
            'a.fqdn': {}
            'b.fqdn': {}
        affinity.handlers.nodes.resolve s.config(),
          s.service('cluster_a', 'service_a').affinity[0]
        .should.eql ['b.fqdn']
      
    
