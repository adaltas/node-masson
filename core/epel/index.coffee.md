
# Epel

Install the Epel Package.

    module.exports =
      use: {}
      configure:
        'masson/core/epel/configure'
      commands:
        'prepare': ->
          options = @config.epel
          @call 'masson/core/epel/prepare', options
        'install': ->
          options = @config.epel
          @call 'masson/core/epel/install', options
