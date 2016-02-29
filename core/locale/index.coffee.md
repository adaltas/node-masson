
# Users Locale

    module.exports = ->
      'configure':
        'masson/core/locale/configure'
      'install': [
        'masson/core/users'
        'masson/core/ssh'
        'masson/core/locale/install'
      ]
    
