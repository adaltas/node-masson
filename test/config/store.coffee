
import fs from 'fs/promises'
import nikita from 'nikita'
import normalize from 'masson/config/normalize'
import store from 'masson/config/store'

describe 'store', ->

  describe 'cluster', ->
    
    it 'return a single cluster', ->
      nikita
        $tmpdir: true
      , ({metadata: {tmpdir}}) ->
        await fs.writeFile "#{tmpdir}/a.json", JSON.stringify {}
        await fs.writeFile "#{tmpdir}/b.json", JSON.stringify {}
        store await normalize
          clusters:
            'cluster_a': services:
              'service_a':
                module: "#{tmpdir}/a.json"
              'service_b':
                module: "#{tmpdir}/b.json"
            'cluster_b': services:
              'service_a':
                module: "#{tmpdir}/a.json"
        .chain()
        .cluster 'cluster_a', (cluster) ->
          cluster.id.should.eql 'cluster_a'
        .cluster 'cluster_b', (cluster) ->
          cluster.id.should.eql 'cluster_b'
  
  describe 'cluster_names', ->
    
    it 'return all clusters', ->
      nikita
        $tmpdir: true
      , ({metadata: {tmpdir}}) ->
        await fs.writeFile "#{tmpdir}/a.json", JSON.stringify {}
        await fs.writeFile "#{tmpdir}/b.json", JSON.stringify {}
        store await normalize
          clusters:
            'cluster_a': services: {}
            'cluster_b': services: {}
            'third_cluster': services: {}
        .cluster_names()
        .should.eql ['cluster_a', 'cluster_b', 'third_cluster']
    
    it 'match a globbing expression', ->
      nikita
        $tmpdir: true
      , ({metadata: {tmpdir}}) ->
        await fs.writeFile "#{tmpdir}/a.json", JSON.stringify {}
        await fs.writeFile "#{tmpdir}/b.json", JSON.stringify {}
        store await normalize
          clusters:
            'cluster_a': services: {}
            'cluster_b': services: {}
            'third_cluster': services: {}
        .cluster_names 'cluster_*'
        .should.eql ['cluster_a', 'cluster_b']
  
  describe 'service', ->
    
    it 'return a single service', ->
      nikita
        $tmpdir: true
      , ({metadata: {tmpdir}}) ->
        await fs.writeFile "#{tmpdir}/a.json", JSON.stringify {}
        await fs.writeFile "#{tmpdir}/b.json", JSON.stringify {}
        store await normalize
          clusters:
            'cluster_a': services:
              'service_a':
                module: "#{tmpdir}/a.json"
              'service_b':
                module: "#{tmpdir}/b.json"
            'cluster_b': services:
              'service_a':
                module: "#{tmpdir}/a.json"
        .chain()
        .service 'cluster_a', 'service_b', (service) ->
          service.id.should.eql 'service_b'
        .service 'cluster_b', 'service_a', (service) ->
          service.id.should.eql 'service_a'
          
    it 'take a single argument', ->
      nikita
        $tmpdir: true
      , ({metadata: {tmpdir}}) ->
        await fs.writeFile "#{tmpdir}/a.json", JSON.stringify {}
        await fs.writeFile "#{tmpdir}/b.json", JSON.stringify {}
        store await normalize
          clusters:
            'cluster_a': services:
              'service_a':
                module: "#{tmpdir}/a.json"
              'service_b':
                module: "#{tmpdir}/b.json"
            'cluster_b': services:
              'service_a':
                module: "#{tmpdir}/a.json"
        .chain()
        .service 'cluster_a:service_b', (service) ->
          service.id.should.eql 'service_b'
        .service 'cluster_b:service_a', (service) ->
          service.id.should.eql 'service_a'
        
  describe 'service_names', ->
    
    config = (tmpdir) ->
      clusters:
        'cluster_a': services:
          'service_a':
            module: "#{tmpdir}/sth.json"
          'third_service':
            module: "#{tmpdir}/sth.json"
        'cluster_b': services:
          'third_service':
            module: "#{tmpdir}/sth.json"
        'third_cluster': services:
          'service_b':
            module: "#{tmpdir}/sth.json"
          'third_service':
            module: "#{tmpdir}/sth.json"
    
    it 'with no arguments', ->
      nikita
        $tmpdir: true
      , ({metadata: {tmpdir}}) ->
        await fs.writeFile "#{tmpdir}/sth.json", JSON.stringify {}
        store await normalize config(tmpdir)
        .service_names()
        .should.eql [
          'cluster_a:service_a', 'cluster_a:third_service'
          'cluster_b:third_service'
          'third_cluster:service_b', 'third_cluster:third_service']

    it 'globbing on cluster and service', ->
      nikita
        $tmpdir: true
      , ({metadata: {tmpdir}}) ->
        await fs.writeFile "#{tmpdir}/sth.json", JSON.stringify {}
        store await normalize config(tmpdir)
        .service_names 'cluster_*:service_*'
        .should.eql ['cluster_a:service_a']

    it 'all clusters and glob services', ->
      nikita
        $tmpdir: true
      , ({metadata: {tmpdir}}) ->
        await fs.writeFile "#{tmpdir}/sth.json", JSON.stringify {}
        store await normalize config(tmpdir)
        .service_names 'service_*'
        .should.eql ['cluster_a:service_a', 'third_cluster:service_b']

    it 'glob clusters and all services', ->
      nikita
        $tmpdir: true
      , ({metadata: {tmpdir}}) ->
        await fs.writeFile "#{tmpdir}/sth.json", JSON.stringify {}
        store await normalize config(tmpdir)
        .service_names 'cluster_*:'
        .should.eql ['cluster_a:service_a', 'cluster_a:third_service', 'cluster_b:third_service']

  describe 'nodes', ->
    
    it 'return all commands', ->
      nikita
        $tmpdir: true
      , ({metadata: {tmpdir}}) ->
        await fs.writeFile "#{tmpdir}/sth.json", JSON.stringify {}
        store await normalize
          nodes:
            'a.fqdn': ip: '10.10.10.1'
            'b.fqdn': ip: '10.10.10.2'
        .nodes()
        .should.eql [
          id: 'a.fqdn'
          fqdn: 'a.fqdn'
          hostname: 'a'
          ip: '10.10.10.1'
          services: []
        ,
          id: 'b.fqdn'
          fqdn: 'b.fqdn'
          hostname: 'b'
          ip: '10.10.10.2'
          services: []
        ]

  describe 'commands', ->
    
    it 'return all commands', ->
      nikita
        $tmpdir: true
      , ({metadata: {tmpdir}}) ->
        await fs.writeFile "#{tmpdir}/sth.json", JSON.stringify {}
        store await normalize
          clusters:
            'cluster_a': services:
              'service_a':
                module: "#{tmpdir}/sth.json"
                commands:
                  'command_1': (->)
                  'command_2': (->)
              'service_b':
                module: "#{tmpdir}/sth.json"
                commands:
                  'command_2': (->)
                  'command_3': (->)
            'cluster_b': services:
              'service_a':
                module: "#{tmpdir}/sth.json"
                commands:
                  'command_1': (->)
        .commands()
        .should.eql ['command_1', 'command_2', 'command_3']
