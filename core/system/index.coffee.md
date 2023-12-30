
# System

* Update SeLinux and optionnaly reboot the system on change
* Set system limits
* Install Unix groups and users
* Add system profile scripts

    export default
      deps: {}
      configure:
        'masson/core/system/configure'
      commands:
        'install':
          'masson/core/system/install'
