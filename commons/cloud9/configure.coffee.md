
# Cloud9 Configure

    module.exports = handler: ->
      @config.cloud9 ?= {}
      @config.cloud9.path ?= '/usr/lib/cloud9'
      @config.cloud9.github ?= 'https://github.com/ajaxorg/cloud9.git'
      @config.cloud9.proxy ?= @config.proxy
