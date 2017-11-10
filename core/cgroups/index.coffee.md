
# Cgroups

Configure cgroups for limiting resources.

For now a group controller can only be set to CPU. It works on both redhat
6.x/7.x releases and can be used at runtime in other modules to retrieve the 
cgroup cpu mount point.

    module.exports =
      configure:
        'masson/core/cgroups/configure'
      commands:
        'install':
          'masson/core/cgroups/install'
