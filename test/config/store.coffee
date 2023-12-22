
import normalize from 'masson/config/normalize'
import store from 'masson/config/store'
import nikita from 'nikita'
import fs from 'fs'

describe 'store', ->

  tmp = '/tmp/masson-test'
  beforeEach ->
    nikita.fs.mkdir tmp
  afterEach ->
    nikita.fs.remove tmp, recursive: true

  describe 'cluster', ->
    
    it 'return a single cluster', ->
      fs.writeFileSync "#{tmp}/a.json", JSON.stringify {}
      fs.writeFileSync "#{tmp}/b.json", JSON.stringify {}
      store normalize
        clusters:
          'cluster_a': services:
            'service_a':
              module: "#{tmp}/a"
            'service_b':
              module: "#{tmp}/b"
          'cluster_b': services:
            'service_a':
              module: "#{tmp}/a"
      .chain()
      .cluster 'cluster_a', (cluster) ->
        cluster.id.should.eql 'cluster_a'
      .cluster 'cluster_b', (cluster) ->
        cluster.id.should.eql 'cluster_b'
  
  describe 'cluster_names', ->
    
    it 'return all clusters', ->
      fs.writeFileSync "#{tmp}/a.json", JSON.stringify {}
      fs.writeFileSync "#{tmp}/b.json", JSON.stringify {}
      store normalize
        clusters:
          'cluster_a': services: {}
          'cluster_b': services: {}
          'third_cluster': services: {}
      .cluster_names()
      .should.eql ['cluster_a', 'cluster_b', 'third_cluster']
    
    it 'match a globbing expression', ->
      fs.writeFileSync "#{tmp}/a.json", JSON.stringify {}
      fs.writeFileSync "#{tmp}/b.json", JSON.stringify {}
      store normalize
        clusters:
          'cluster_a': services: {}
          'cluster_b': services: {}
          'third_cluster': services: {}
      .cluster_names 'cluster_*'
      .should.eql ['cluster_a', 'cluster_b']
  
  describe 'service', ->
    
    it 'return a single service', ->
      fs.writeFileSync "#{tmp}/a.json", JSON.stringify {}
      fs.writeFileSync "#{tmp}/b.json", JSON.stringify {}
      store normalize
        clusters:
          'cluster_a': services:
            'service_a':
              module: "#{tmp}/a"
            'service_b':
              module: "#{tmp}/b"
          'cluster_b': services:
            'service_a':
              module: "#{tmp}/a"
      .chain()
      .service 'cluster_a', 'service_b', (service) ->
        service.id.should.eql 'service_b'
      .service 'cluster_b', 'service_a', (service) ->
        service.id.should.eql 'service_a'
          
    it 'take a single argument', ->
      fs.writeFileSync "#{tmp}/a.json", JSON.stringify {}
      fs.writeFileSync "#{tmp}/b.json", JSON.stringify {}
      store normalize
        clusters:
          'cluster_a': services:
            'service_a':
              module: "#{tmp}/a"
            'service_b':
              module: "#{tmp}/b"
          'cluster_b': services:
            'service_a':
              module: "#{tmp}/a"
      .chain()
      .service 'cluster_a:service_b', (service) ->
        service.id.should.eql 'service_b'
      .service 'cluster_b:service_a', (service) ->
        service.id.should.eql 'service_a'
      
  describe 'service_names', ->
    
    config = clusters:
      'cluster_a': services:
        'service_a':
          module: "#{tmp}/sth"
        'third_service':
          module: "#{tmp}/sth"
      'cluster_b': services:
        'third_service':
          module: "#{tmp}/sth"
      'third_cluster': services:
        'service_b':
          module: "#{tmp}/sth"
        'third_service':
          module: "#{tmp}/sth"
    
    it 'with no arguments', ->
      fs.writeFileSync "#{tmp}/sth.json", JSON.stringify {}
      store normalize config
      .service_names()
      .should.eql [
        'cluster_a:service_a', 'cluster_a:third_service'
        'cluster_b:third_service'
        'third_cluster:service_b', 'third_cluster:third_service']

    it 'globbing on cluster and service', ->
      fs.writeFileSync "#{tmp}/sth.json", JSON.stringify {}
      store normalize config
      .service_names 'cluster_*:service_*'
      .should.eql ['cluster_a:service_a']

    it 'all clusters and glob services', ->
      fs.writeFileSync "#{tmp}/sth.json", JSON.stringify {}
      store normalize config
      .service_names 'service_*'
      .should.eql ['cluster_a:service_a', 'third_cluster:service_b']

    it 'glob clusters and all services', ->
      fs.writeFileSync "#{tmp}/sth.json", JSON.stringify {}
      store normalize config
      .service_names 'cluster_*:'
      .should.eql ['cluster_a:service_a', 'cluster_a:third_service', 'cluster_b:third_service']

  describe 'nodes', ->
    
    it 'return all commands', ->
      fs.writeFileSync "#{tmp}/sth.json", JSON.stringify {}
      store normalize
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
      fs.writeFileSync "#{tmp}/sth.json", JSON.stringify {}
      store normalize
        clusters:
          'cluster_a': services:
            'service_a':
              module: "#{tmp}/sth"
              commands:
                'command_1': (->)
                'command_2': (->)
            'service_b':
              module: "#{tmp}/sth"
              commands:
                'command_2': (->)
                'command_3': (->)
          'cluster_b': services:
            'service_a':
              module: "#{tmp}/sth"
              commands:
                'command_1': (->)
      .commands()
      .should.eql ['command_1', 'command_2', 'command_3']
