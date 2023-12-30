
# # Network

# Modify the various network related configuration files such as
# "/etc/hosts" and "/etc/resolv.conf".

# * Fill "/etc/hosts" with node hostname and IP information
# * Fill "/etc/hosts" with all registed hosts if option "hosts_auto" is activated
# * Set hostname unless option "hostname_disabled" is activated
# * Write DNS configuration if option "resolv" is defined
# * Customize the network interfaces if option "ifcg" is provided

export default
  deps:
    bind_server: module: 'masson/core/bind_server'
  configure:
    'masson/core/network/configure'
  commands:
    'check': [
      'masson/core/bind_client'
      'masson/core/network/check'
    ]
    'install':
      'masson/core/network/install'
    'restart':
      'masson/core/network/restart'
