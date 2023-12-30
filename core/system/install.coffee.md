
# System Install

    export default header: 'System Install', handler: ({options}) ->

## SELinux

Security-Enhanced Linux (SELinux) is a mandatory access control (MAC) security
mechanism implemented in the kernel.

This action update the configuration file present in "/etc/selinux/config". The
OS will reboot if SELINUX was modified.

      @file
        header: 'SELinux'
        target: '/etc/selinux/config'
        match: /^SELINUX=.*/mg
        replace: "SELINUX=#{options.selinux}"
        backup: true
      @system.execute
        header: 'Reboot'
        cmd: 'shutdown -r now \'Rebooting after modifying SELinux\''
        if: -> @status -1 and options.reboot

# Kernel

Configure kernel parameters at runtime. There are no properties set by default,
here's a suggestion:

*    vm.swappiness = 10
*    vm.overcommit_memory = 1
*    vm.overcommit_ratio = 100
*    net.core.somaxconn = 4096 (default socket listen queue size 128)

      @tools.sysctl
        header: 'Kernel'
        properties: options.sysctl
        merge: true
        comment: true

## Limits

On CentOs 6.4, The default values are:

```bash
cat /etc/security/limits.conf
*                -    nofile          8192
cat /etc/security/limits.d/90-nproc.conf
*          soft    nproc     1024
root       soft    nproc     unlimited
```

      @system.limits merge
        header: "Global System Limits"
        target: '/etc/security/limits.conf'
        backup: true
        system: true
      , options.limits

## Groups

Create the users defined inside the "hdp.groups" configuration. See the
[nikita "group" documentation][nikita_group] for additionnal information.

      @call header: 'Groups', ->
        @system.group group for _, group of options.groups

## Users

Create the users defined inside the "hdp.users" configuration. See the
[nikita "user" documentation][nikita_user] for additionnal information.

      @call header: 'Users', ->
        @system.user user for _, user of options.users

## Profile

Publish scripts inside the profile directory, located in "/etc/profile.d".

      @call header: 'Profile', ->
        @file (
          target: "/etc/profile.d/#{filename}"
          content: content
          eof: true
        ) for filename, content of options.profile

## Dependencies

    {merge} = require 'mixme'

[nikita_group]: https://github.com/wdavidw/node-nikita/blob/master/src/group.coffee.md
[nikita_user]: https://github.com/wdavidw/node-nikita/blob/master/src/user.coffee.md
