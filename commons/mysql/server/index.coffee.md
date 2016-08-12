
# Mysql Server
    
    module.exports = ->
      'configure':
        'masson/commons/mysql/server/configure'
      'install': [
        'masson/core/iptables'
        'masson/commons/mysql/server/install'
        'masson/commons/mysql/client'
      ]
