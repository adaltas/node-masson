
should = require 'should'
nikita = require 'nikita'
tree = require '../lib/tree'

describe 'tree commands', ->

  tmp = '/tmp/masson-test'
  beforeEach (next) ->
    require('module')._cache = {}
    nikita.mkdir destination: tmp, next
  afterEach (next) -> nikita.remove tmp, next
  
  describe 'default', ->

    it 'find default commands', (next) ->
      nikita.file [
        destination: "#{tmp}/module_1.coffee"
        content: """
        module.exports = [
          '#{tmp}/module_2'
          {name: 'middleware 1', handler: (next) -> next()}
          '#{tmp}/module_3'
        ]
        """
      ,
        destination: "#{tmp}/module_2.coffee"
        content: """
        module.exports = [name: 'middleware 2', handler: (next) -> next()]
        """
      ,
        destination: "#{tmp}/module_3.coffee"
        content: """
        module.exports = [name: 'middleware 3', handler: (next) -> next()]
        """
      ], (err) ->
        commands = tree("#{tmp}/module_1").commands()
        commands.should.eql [ 'install' ]
        next()

  describe 'user', ->

    it 'find user commands', (next) ->
      nikita.file [
        destination: "#{tmp}/module_1.coffee"
        content: """
        module.exports = [
          '#{tmp}/module_2'
          {name: 'middleware 1', handler: (next) -> next()}
          {commands: ['command1'], modules: ['#{tmp}/module_3']}
        ]
        """
      ,
        destination: "#{tmp}/module_2.coffee"
        content: """
        module.exports = [ commands: 'command2', name: 'middleware 2', handler: (next) -> next()]
        """
      ,
        destination: "#{tmp}/module_3.coffee"
        content: """
        module.exports = [ commands: ['command3'], name: 'middleware 3', handler: (next) -> next()]
        """
      ], (err) ->
        commands = tree("#{tmp}/module_1").commands()
        commands.should.eql [ 'install', 'command1', 'command2', 'command3' ]
        next()
