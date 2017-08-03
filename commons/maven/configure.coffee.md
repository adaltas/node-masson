
# Maven Configure

    module.exports = ->
      service = migration.call @, service, 'masson/commons/maven', ['maven'], {}
      options = @config.maven = service.options
        
      options.source ?= 'http://apache.crihan.fr/dist/maven/maven-3/3.3.9/binaries/apache-maven-3.3.9-bin.tar.gz'
      options.dirname ?= /^(.*)-bin/.exec(path.basename options.source)[1]

## Dependencies

    path = require 'path'
