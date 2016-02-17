
# Mysql Server
    
    module.exports = ->
      'configure':
        'masson/commons/mysql_server/configure'
      'install': [
        'masson/core/iptables'
        'masson/commons/mysql_server/install'
        'masson/commons/mysql_client'
      ]
