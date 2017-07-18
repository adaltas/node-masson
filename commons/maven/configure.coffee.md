
# Maven Configure

    module.exports = handler: ->
      @config.maven ?= {}
      @config.maven.source ?= 'http://apache.crihan.fr/dist/maven/maven-3/3.3.9/binaries/apache-maven-3.3.9-bin.tar.gz'
      @config.maven.dirname ?= /^(.*)-bin/.exec(path.basename @config.maven.source)[1]

## Dependencies

    path = require 'path'
