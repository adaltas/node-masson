
# Maven

Currently being written, not yet registered in any config.

    exports = module.exports = []
    exports.push 'masson/bootstrap'

## Configuration

    exports.configure = (ctx) ->
      ctx.config.maven ?= {}
      ctx.config.maven.source ?= 'http://apache.crihan.fr/dist/maven/maven-3/3.3.9/binaries/apache-maven-3.3.9-bin.tar.gz'
      ctx.config.maven.dirname ?= /^(.*)-bin/.exec(path.basename ctx.config.maven.source)[1]

## Prepare

    exports.push commands: 'prepare', header: 'Maven', handler: ->
      @cache
        ssh: null
        source: @config.maven.source

## Installation

    exports.push commands: 'install', header: 'Maven', handler: ->
      @download
        source: @config.maven.source
        destination: '/var/tmp/maven.tar.gz'
      @mkdir
        destination: "/usr/ryba"
      @extract
        source: '/var/tmp/maven.tar.gz'
        destination: '/usr/ryba'
      @link
        source: "/usr/ryba/#{@config.maven.dirname}"
        destination: '/usr/ryba/maven'
      @link
        source: '/usr/ryba/maven/bin/mvn'
        destination: '/usr/ryba/bin/mvn'

## Dependencies

    path = require 'path'
