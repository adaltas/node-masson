
# System Install

    module.exports = header: 'System Install', handler: ->
      {system} = @config

## SELinux

Security-Enhanced Linux (SELinux) is a mandatory access control (MAC) security
mechanism implemented in the kernel.

This action update the configuration file present in "/etc/selinux/config". The
OS will reboot if SELINUX was modified.

      @file
        header: 'SELinux'
        target: '/etc/selinux/config'
        match: /^SELINUX=.*/mg
        replace: "SELINUX=#{if system.selinux then 'enforcing' else 'disabled'}"
      @system.execute
        header: 'Reboot'
        cmd: 'shutdown -r now'
        if: -> @status -1

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
        target: "/etc/security/limits.conf"
        backup: true
        system: true
      , system.limits

## Groups

Create the users defined inside the "hdp.groups" configuration. See the
[nikita "group" documentation][nikita_group] for additionnal information.

      @call header: 'Groups', ->
        @system.group group for _, group of system.groups

## Users

Create the users defined inside the "hdp.users" configuration. See the
[nikita "user" documentation][nikita_user] for additionnal information.

      @call header: 'Users', ->
        @system.user user for _, user of system.users

## Profile

Publish scripts inside the profile directory, located in "/etc/profile.d".

      @call header: 'Profile', ->
        @file (
          target: "/etc/profile.d/#{filename}"
          content: content
          eof: true
        ) for filename, content of @config.profile

## Dependencies

    {merge} = require 'nikita/lib/misc'

[nikita_group]: https://github.com/wdavidw/node-nikita/blob/master/src/group.coffee.md
[nikita_user]: https://github.com/wdavidw/node-nikita/blob/master/src/user.coffee.md
