
# Mysql Server
    
    module.exports =
      use:
        iptables: implicit: true, module: 'masson/core/iptables'
      configure:
        'masson/commons/mysql/server/configure'
      commands:
        'install': [
          'masson/commons/mysql/server/install'
        ]
