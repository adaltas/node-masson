
# # SSH

# * Set configuration properties to the SSHD daemon
# * Customize the banner text on user SSH login
# * Upload user publiic and private keys
# * Defined user authorized keys

export default
  deps:
    system: module: 'masson/core/system', local: true
    yum: module: 'masson/core/yum', local: true
    apt: module: 'masson/core/apt', local: true
  configure:
    'masson/core/ssh/configure'
  commands:
    'check':
      'masson/core/ssh/check'
    'install': [
      'masson/core/ssh/install'
      'masson/core/ssh/check'
    ]
