
context = require '../src/context'
should = require 'should'

describe 'properties', ->

  it 'parse', ->
    ctx = context
      servers: [
        host: 'serverA'
        roles: ['base', 'master']
      ,
        host: 'serverB'
        roles: ['base', 'slave']
      ,
        host: 'serverC'
        roles: ['base', 'slave']
      ]
      roles:
        base: [ 'ssh', 'network', 'profile', 'proxy' ]
        slave: [ 'ganglia_monitor', 'mysql' ]
        master: [ 'ganglia_collector', 'mysql_server' ]
    ctx.servers().should.eql ['serverA','serverB','serverC']
    ctx.servers(action: 'mysql').should.eql ['serverB','serverC']
    ctx.servers(action: 'ganglia_collector').should.eql ['serverA']
    ctx.servers(role: 'slave').should.eql ['serverB','serverC']
    