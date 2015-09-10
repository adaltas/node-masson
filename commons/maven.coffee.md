
# Maven

Currently being written, not yet registered in any config.

    exports = module.exports = []
    exports.push 'masson/bootstrap'

## Configuration

    exports.configure = (ctx) ->
      ctx.config.maven ?= {}
      ctx.config.maven.source ?= 'http://apache.websitebeheerjd.nl/maven/maven-3/3.3.3/binaries/apache-maven-3.3.3-bin.tar.gz'

## Installation

    exports.push name: 'Maven # Installation', handler: ->
      @download
        source: ctx.config.maven.source
        destination: '/var/tmp/maven.tar.gz'
      @mkdir
        destination: "/usr/lib/maven"
      @extract
        source: '/var/tmp/maven.tar.gz'
        destination: '/usr/lib/maven'
