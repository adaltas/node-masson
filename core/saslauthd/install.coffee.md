
# SASLAuthd Install

    export default header: 'SASLAuthd Install', handler: ({options}) ->

## Identities

```bash
cat /etc/passwd | grep saslauth
saslauth:x:995:76:Saslauthd user:/run/saslauthd:/sbin/nologin
cat /etc/group | grep saslauth
saslauth:x:76:
```

      @system.group header: 'Group', options.group
      @system.user header: 'User', options.user

## Packages

      @call header: 'Packages', ->
        @service 'cyrus-sasl'
        @service 'cyrus-sasl-ldap'

## Configuration

      @file.properties
        header: 'Sysconf'
        target: '/etc/sysconfig/saslauthd'
        content: options.sysconfig
        mode: 0o0644
      @file.properties
        header: 'Conf'
        target: options.conf_file
        content: options.conf
        mode: 0o0644
        separator: ': '

## Start

      @service
        header: 'Start'
        if: -> @status()
        srv_name: 'saslauthd'
        startup: true
        state: ['started', 'restarted']
