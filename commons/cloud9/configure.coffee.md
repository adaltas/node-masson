
# Cloud9 Configure

    module.exports = (service) ->
      options = service.options

      options.path ?= '/usr/lib/cloud9'
      options.github ?= 'https://github.com/ajaxorg/cloud9.git'
      # options.proxy ?= service.deps.proxy.options.http_proxy
