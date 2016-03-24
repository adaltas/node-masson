
# GIT Install

    module.exports = header: 'Git Install', handler: ->
    
## Package

Install the git package.

      @service
        header: 'Git # Package'
        name: 'git'

## Config

Deploy the git configuration.

      @call header: 'Git # Config', ->
        {merge, properties, global} = @config.git
        unless @registered 'git_config'
          @register 'git_config', (options) ->
            throw Error unless options.config
            options.content = misc.merge {}, properties, options.config
            options.merge ?= merge
            @write_ini options
        @git_config
          uid: 'root'
          gid: 'root'
          destination: '/etc/gitconfig'
          config: global
          if: global
        @remove
          if: global is false
          destination: '/etc/gitconfig'
        for user in @config.users then do (user) ->
          @git_config
            destination: file
            uid: user.name or user.uid
            gid: user.gid

## Dependencies

    misc = require 'mecano/lib/misc'
