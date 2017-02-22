
# GIT Install

    module.exports = header: 'Git Install', handler: ->

## Package

Install the git package.

      @service
        header: 'Package'
        name: 'git'

## Config

Deploy the git configuration.

      @call header: 'Config', ->
        {merge, properties, global, users} = @config.git
        @registry.register 'git_config', (options) ->
          throw Error unless options.config
          options.content = misc.merge {}, properties, options.config
          options.merge ?= merge
          @file.ini options
        @git_config
          uid: 'root'
          gid: 'root'
          target: '/etc/gitconfig'
          config: global
          if: global
        @system.remove
          if: global is false
          target: '/etc/gitconfig'
        @git_config (
          target: @config.users[user].home or "/home/#{user}"
          uid: @config.users[user].uid or @config.users[user].name
          gid: @config.users[user].gid or @config.users[user].group
          config: config
        ) for user, config in users

## Dependencies

    misc = require 'mecano/lib/misc'
