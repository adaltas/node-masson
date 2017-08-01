
# Cloud9 Configure

    module.exports = ->
      options = @config.cloud9 ?= {}
      options.path ?= '/usr/lib/cloud9'
      options.github ?= 'https://github.com/ajaxorg/cloud9.git'
      options.proxy ?= @config.proxy
