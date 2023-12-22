
import normalize from 'masson/config/normalize'
import store from 'masson/config/store'
import nikita from 'nikita'
import fs from 'fs'

describe 'chain', ->

  tmp = '/tmp/masson-test'
  beforeEach ->
    nikita.fs.mkdir tmp
  afterEach ->
    nikita.fs.remove tmp, recursive: true
  
  it 'chain/unchain', ->
    fs.writeFileSync "#{tmp}/a.json", JSON.stringify {}
    fs.writeFileSync "#{tmp}/b.json", JSON.stringify {}
    store normalize
      clusters: 'cluster_a': services:
        'service_a':
          module: "#{tmp}/a"
        'service_b':
          module: "#{tmp}/b"
    .chain()
    .service 'cluster_a', 'service_a', (service) ->
      service.id.should.eql 'service_a'
    .service 'cluster_a', 'service_b', (service) ->
      service.id.should.eql 'service_b'
    .unchain()
    .service 'cluster_a', 'service_a'
    .id
    .should.eql 'service_a'
