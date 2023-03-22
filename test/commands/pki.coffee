
normalize = require '../../lib/config/normalize'
params = require '../../lib/params'
fs = require('fs').promises
nikita = require 'nikita'
{shell} = require 'shell'

describe 'command pki', ->
  
  tmp = '/tmp/masson-test'
  beforeEach ->
    require('module')._cache = {}
    nikita.fs.mkdir tmp
  afterEach ->
    nikita.fs.remove tmp, recursive: true

  it 'CA generate', ->
    write = process.stdout.write
    data = null
    process.stdout.write = (d)->
      data = d
      true
    await fs.writeFile "#{tmp}/a.json", JSON.stringify {}
    config = normalize {}
    await shell(params).route ['pki', '--dir', "#{tmp}", 'ca'], config
    process.stdout.write = write
    data.should.eql """
    
    Certificate files generated:
    * Key: "/tmp/masson-test/ca.key.pem"
    * Certificate: "/tmp/masson-test/ca.cert.pem"
    * Subject: "/C=FR/O=Adaltas/L=Paris/CN=adaltas.com"
    
    
    """
