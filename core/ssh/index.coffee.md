
# SSH

* Set configuration properties to the SSHD daemon
* Customize the banner text on user SSH login
* Upload user publiic and private keys
* Defined user authorized keys

    module.exports =
      use:
        system: 'masson/core/system'
        yum: 'masson/core/yum'
      configure:
        'masson/core/ssh/configure'
      commands:
        'install':
          'masson/core/ssh/install'
