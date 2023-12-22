
import normalize from 'masson/config/normalize'
import store from 'masson/config/store'
import nikita from 'nikita'
import fs from 'fs'

describe 'normalize service nodes', ->

  tmp = '/tmp/masson-test'
  beforeEach ->
    nikita.fs.mkdir tmp
  afterEach ->
    nikita.fs.remove tmp, recursive: true
  
  it 'is normalized with default values', ->
    fs.writeFileSync "#{tmp}/a.json", JSON.stringify {}
    res = store normalize
      clusters: 'cluster_a': services: 'service_a':
        module: "#{tmp}/a"
        affinity:
          type: 'nodes'
          values: 'a.fqdn'
      nodes:
        'a.fqdn': {}
    .service 'cluster_a', 'service_a'
    .instances.should.eql [
        id: 'a.fqdn'
        cluster: 'cluster_a'
        service: 'service_a'
        options: {}
        node:
          id: 'a.fqdn'
          fqdn: 'a.fqdn'
          hostname: 'a'
          services: [
            cluster: 'cluster_a'
            module: '/tmp/masson-test/a'
            service: 'service_a'
          ]
      ]
  
  it 'overwrite options', ->
    fs.writeFileSync "#{tmp}/a.json", JSON.stringify {}
    res = store normalize
      clusters: 'cluster_a': services: 'service_a':
        module: "#{tmp}/a"
        affinity:
          type: 'nodes'
          values: 'a.fqdn'
        options:
          'my_option_in_service_options': 'my value'
          'my_option_in_service_nodes': 'should be overwritten'
          'my_option_in_nodes': 'should be overwritten'
        nodes:
          'a.fqdn':
            'my_option_in_service_nodes': 'my value'
      nodes:
        'a.fqdn': services:
          'cluster_a:service_a':
            'my_option_in_nodes': 'my value'
            'my_option_in_service_nodes': 'should be overwritten'
    .service 'cluster_a', 'service_a'
    .instances.filter( (instance) -> instance.node.id is 'a.fqdn')[0]
    .options.should.eql
      'my_option_in_service_options': 'my value'
      'my_option_in_service_nodes': 'my value'
      'my_option_in_nodes': 'my value'
