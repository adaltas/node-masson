
# Cloud9 Configure

    module.exports = ->
      cloud9 = @config.cloud9 ?= {}
      cloud9.path ?= '/usr/lib/cloud9'
      cloud9.github ?= 'https://github.com/ajaxorg/cloud9.git'
      cloud9.proxy ?= @config.proxy
