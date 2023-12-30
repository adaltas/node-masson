
export default
  deps:
    iptables: module: 'masson/core/iptables/index', local: true
    system: module: 'masson/core/system/index', local: true #rngd entropy
    ssl: module: '@rybajs/tools/ssl/index', local: true
    network: module: 'masson/core/network/index', local: true
    rngd: module: 'masson/core/rngd/index', local: true, auto: true, implicit: true
  configure:
    'masson/core/freeipa/server/configure'
  commands:
    'check':
      'masson/core/freeipa/server/check'
    'install': [
      'masson/core/freeipa/server/install'
      # 'masson/core/freeipa/server/start'
      # 'masson/core/freeipa/server/check'
    ]
    'start':
      'masson/core/freeipa/server/start'
    'status':
      'masson/core/freeipa/server/status'
    'stop':
      'masson/core/freeipa/server/stop'
