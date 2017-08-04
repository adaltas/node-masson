
# SSH

* Set configuration properties to the SSHD daemon
* Customize the banner text on user SSH login
* Upload user publiic and private keys
* Defined user authorized keys

    module.exports =
      use:
        system: module: 'masson/core/system', local: true
        yum: module: 'masson/core/yum', local: true
      configure:
        'masson/core/ssh/configure'
      commands:
        'check': ->
          options = @config.ssh
          @call 'masson/core/ssh/check', options
        'install': ->
          options = @config.ssh
          @call 'masson/core/ssh/install', options
          @call 'masson/core/ssh/check', options
