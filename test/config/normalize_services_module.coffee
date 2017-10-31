
normalize = require '../../lib/config/normalize'
store = require '../../lib/config/store'
nikita = require 'nikita'
fs = require 'fs'

describe 'normalize service module', ->

  tmp = '/tmp/masson-test'
  beforeEach ->
    require('module')._cache = {}
    nikita
    .system.mkdir target: tmp
    .promise()
  afterEach ->
    nikita
    .system.remove tmp
    .promise()
  
  it 'merge module definition', ->
    fs.writeFileSync "#{tmp}/a.json", JSON.stringify
      my_property: true
    res = store normalize
      clusters: 'cluster_a': services: 'service_a': module: "#{tmp}/a"
    .service 'cluster_a', 'service_a'
    .my_property
    .should.be.true()

  it 'ensure object type', ->
    fs.writeFileSync "#{tmp}/invalid_type.js", 'module.exports = function(){}'
    try
      normalize
        clusters: 'cluster_a': services: 'service_a': module: "#{tmp}/invalid_type"
      throw Error 'Dont get here'
    catch err
      err.message.should.eql "Invalid Service Definition: expect an object for module \"#{tmp}/invalid_type\", got \"function\""

  it 'catch invalid syntax', ->
    fs.writeFileSync "#{tmp}/invalid_syntax.js", 'module.exports = this is messed up'
    try
      normalize
        clusters: 'cluster_a': services: 'service_a': module: "#{tmp}/invalid_syntax"
      throw Error 'Dont get here'
    catch err
      err.message.should.eql "Unexpected identifier"
