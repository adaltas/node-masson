
# Users Locale

    export default
      deps:
        system: module: 'masson/core/system', local: true, required: true
      configure:
        'masson/core/locale/configure'
      commands:
        'install':
          'masson/core/locale/install'
