
import normalize from 'masson/config/normalize'
import store from 'masson/config/store'
import nikita from 'nikita'
import fs from 'fs'

describe 'normalize nodes', ->

  tmp = '/tmp/masson-test'
  beforeEach ->
    nikita.fs.mkdir tmp
  afterEach ->
    nikita.fs.remove tmp, recursive: true
  
  it 'value is true', ->
    store normalize
      nodes:
        'a.fqdn': true
    .node 'a.fqdn'
    .should.eql
      id: 'a.fqdn'
      fqdn: 'a.fqdn'
      hostname: 'a'
      services: []
