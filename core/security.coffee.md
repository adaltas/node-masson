
# Security

This package cover various security related configuration for an operating
system.

    exports = module.exports = []
    exports.push 'masson/bootstrap'

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

    exports.push.configure = (ctx) ->
      ctx.config.security ?= {}
      ctx.config.security.selinux ?= true
      ctx.config.security.limits ?= {}

## SELinux

Security-Enhanced Linux (SELinux) is a mandatory access control (MAC) security 
mechanism implemented in the kernel.

This action update the configuration file present in "/etc/selinux/config".

    exports.push name: 'Security # SELinux', handler: ->
      {selinux} = @config.security
      if selinux
        from = 'disabled'
        to = 'enforcing'
      else
        from = 'enforcing'
        to = 'disabled'
      @write
        destination: '/etc/selinux/config'
        match: /^SELINUX=.*/mg
        replace: "SELINUX=#{to}"
      @execute
        cmd: 'shutdown -r now'
        if: -> @status -1
      , (err, executed) ->
        @log '[WARN masson.core.security] Reboot after SELINUX changes'

# Limits

On CentOs 6.4, The default values are:

```bash
cat /etc/security/limits.conf
*                -    nofile          8192
cat /etc/security/limits.d/90-nproc.conf
*          soft    nproc     1024
root       soft    nproc     unlimited
```

    exports.push name: 'Security # Limits', handler: ->
      {limits} = @config.security
      writes = for filename, content of limits
        destination: "/etc/security/limits.d/#{filename}"
        content: content
        backup: true
      @write writes
