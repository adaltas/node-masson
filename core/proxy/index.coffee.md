
# Proxy

Declare proxy related environment variables as well as 
providing configuration properties which other modules may use.

    module.exports =
      configure:
        'masson/core/proxy/configure'
      commands:
        'install': ->
          options = @config.proxy
          @call 'masson/core/proxy/install', options
