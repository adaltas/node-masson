
# System

* Update SeLinux and optionnaly reboot the system on change
* Set system limits
* Install Unix groups and users
* Add system profile scripts

    module.exports =
      use: {}
      configure:
        'masson/core/system/configure'
      commands:
        'install': ->
          options = @config.system
          @call 'masson/core/system/install', options
