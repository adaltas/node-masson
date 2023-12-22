
import normalize from 'masson/config/normalize'
import store from 'masson/config/store'
import nikita from 'nikita'
import fs from 'fs'

describe 'normalize service module', ->

  tmp = '/tmp/masson-test'
  beforeEach ->
    nikita.fs.mkdir tmp
  afterEach ->
    nikita.fs.remove tmp, recursive: true
  
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
