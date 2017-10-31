
normalize = require '../../lib/config/normalize'
store = require '../../lib/config/store'
nikita = require 'nikita'
fs = require 'fs'

describe 'normalize service commands', ->

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
  
  it 'take an array of string and function', ->
    fs.writeFileSync "#{tmp}/a.json", JSON.stringify {}
    store normalize
      clusters: 'cluster_a': services:
        'service_a': module: "#{tmp}/a", commands:
          my_command: [
            "#{tmp}/a",
            (->)
          ]
    .service 'cluster_a', 'service_a'
    .commands.my_command.should.eql [
      "#{tmp}/a",
      (->)
    ]
  
  it 'convert string and function to function', ->
    fs.writeFileSync "#{tmp}/a.json", JSON.stringify {}
    store normalize
      clusters: 'cluster_a': services:
        'service_a': module: "#{tmp}/a", commands:
          my_string: "#{tmp}/a"
          my_function: (->)
    .service 'cluster_a', 'service_a'
    .commands.should.eql
      my_string: [ "#{tmp}/a" ]
      my_function: [(->)]
    
  it 'accept only array, string and function', ->
    fs.writeFileSync "#{tmp}/a.json", JSON.stringify {}
    ( ->
      normalize clusters: 'cluster_a': services:
        'service_a': module: "#{tmp}/a", commands:
          my_null: null
    ).should.throw 'Invalid Command: accept array, string or function, got null for command "my_null"'
    ( ->
      normalize clusters: 'cluster_a': services:
        'service_a': module: "#{tmp}/a", commands:
          my_null: 123
    ).should.throw 'Invalid Command: accept array, string or function, got 123 for command "my_null"'
