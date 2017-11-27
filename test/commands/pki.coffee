
normalize = require '../../lib/config/normalize'
params = require '../../lib/params'
fs = require 'fs'
nikita = require 'nikita'
parameters = require 'parameters'

describe 'command pki', ->
  
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

  it 'CA generate', (next) ->
    write = process.stdout.write
    data = null
    process.stdout.write = (d)->
      data = d
      true
    fs.writeFileSync "#{tmp}/a.json", JSON.stringify {}
    config = normalize {}
    parameters(params).run ['pki', '--dir', "#{tmp}", 'ca'], config, (err) ->
      process.stdout.write = write
      data.should.eql """
      
      Certificate files generated:
      * Key: "/tmp/masson-test/ca.key.pem"
      * Certificate: "/tmp/masson-test/ca.cert.pem"
      * Subject: "/C=FR/O=Adaltas/L=Paris/CN=adaltas.com"
      
      
      """
      next()
