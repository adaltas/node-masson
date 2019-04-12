
# normalize = require '../../lib/config/normalize'
# params = require '../../lib/params'
fs = require 'fs'
nikita = require 'nikita'
# parameters = require 'parameters'
masson = require '../lib'

describe 'params', ->

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

  it 'can be overwritten from configuration', (next) ->
    write = process.stdout.write
    data = null
    process.stdout.write = (d)->
      data = d
    fs.writeFileSync "#{tmp}/config.json", JSON.stringify
      params: commands: 'help': description: 'Overwrite default description'
    masson ['-c', "#{tmp}/config.json", 'help'], (err) ->
      # parameters(params).route(, config)
      process.stdout.write = write
      data.split(/\r\n|[\n\r\u0085\u2028\u2029]/g)[13]
      .should.eql '    help                    Overwrite default description'
      next()
