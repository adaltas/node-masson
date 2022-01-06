
normalize = require '../../lib/config/normalize'
store = require '../../lib/config/store'
nikita = require 'nikita'
fs = require 'fs'

describe 'normalize nodes', ->

  tmp = '/tmp/masson-test'
  beforeEach ->
    require('module')._cache = {}
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
