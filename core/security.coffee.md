
# Security

This package cover various security related configuration for an operating
system.

## Configuration

*   `selinux` (boolean)   
    Whether SELinux should be activated or not.   
*   `limits` (object)   
    List of files written in "/etc/security/limits.d". Keys are the filename
    and values are the content of the file.

Example:

```json
{
  "security": {
    "selinux": false,
    "limits": {
      "me.conf'": "me - nofile 32768\nme - nproc 65536"
    }
  }
}
```

    module.exports = ->
      @config.security ?= {}
      @config.security.selinux ?= true
      @config.security.limits ?= {}
      'install': header: 'Security', handler: (options) ->

## SELinux

Security-Enhanced Linux (SELinux) is a mandatory access control (MAC) security 
mechanism implemented in the kernel.

This action update the configuration file present in "/etc/selinux/config".

        @file
          header: 'SELinux'
          target: '/etc/selinux/config'
          match: /^SELINUX=.*/mg
          replace: "SELINUX=#{if @config.security.selinux then 'enforcing' else 'disabled'}"

## Reboot

Reboot only if SELINUX was modified.

        @execute
          header: 'Reboot'
          cmd: 'shutdown -r now'
          if: -> @status -1
        , (err, executed) ->
          options.log '[WARN masson.core.security] Reboot after SELINUX changes'

# Limits

On CentOs 6.4, The default values are:

```bash
cat /etc/security/limits.conf
*                -    nofile          8192
cat /etc/security/limits.d/90-nproc.conf
*          soft    nproc     1024
root       soft    nproc     unlimited
```

        @file (
          header: "Limits on #{filename}"
          target: "/etc/security/limits.d/#{filename}"
          content: content
          backup: true
        ) for filename, content of @config.security.limits
