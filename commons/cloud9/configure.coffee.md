
# Cloud9 Configure

    module.exports = ->
      service = migration.call @, service, 'masson/commons/cloud9', ['cloud9'], require('nikita/lib/misc').merge require('.').use,
        git: key: ['git']
        nodejs: key: ['nodejs']
      options = @config.cloud9 ?= {}

      options.path ?= '/usr/lib/cloud9'
      options.github ?= 'https://github.com/ajaxorg/cloud9.git'
      options.proxy ?= @config.proxy
