
# Users Locale

    module.exports =
      use:
        system: module: 'masson/core/system', implicit: true, local: true
      configure:
        'masson/core/locale/configure'
      commands:
        'install': ->
          options = @config.locale
          @call 'masson/core/locale/install', options
