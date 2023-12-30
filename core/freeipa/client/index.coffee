
export default
  deps:
    iptables: module: 'masson/core/iptables', local: true
    ssl: module: '@rybajs/tools/ssl', local: true
    network: module: 'masson/core/network', local: true
    ipa_server:  module: 'masson/core/freeipa/server'
  configure:
    'masson/core/freeipa/client/configure'
  commands:
    'check':
      'masson/core/freeipa/client/check'
    'install': [
      'masson/core/freeipa/client/install'
      # 'masson/core/freeipa/configure/start'
      # 'masson/core/freeipa/configure/check'
    ]
