
# DNS

Forward and reverse DNS mandatory to many service. For exemple both Kerberos 
and Hadoop require a working DNS environment to work properly. A common 
solution to solve an incorrect DNS environment is to install your own DNS 
server. Investigate the "masson/core/bind_server" module for additional 
information.

TODO: in case we are running a local bind server inside the cluster and if this 
server isnt the one currently being installed, we could wait for the server to 
be started before checking the forward and reverse dns of the server.

Dig isn't available by default on CentOS and is installed by the 
"masson/core/bind_client" dependency.

    ipRegex = /^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$/
    exports = module.exports = []
    exports.push 'masson/bootstrap'
    exports.push 'masson/core/bind_client'

## DNS Forward Lookup

Check forward DNS lookup using the configured DNS configuration present inside
"/etc/resolv.conf". Internally, the exectuted command uses "dig".

    exports.push name: 'Network Check # DNS Forward Lookup', handler: (ctx, next) ->
      # I didnt find how to restrict dig to return only A records like it
      # does for CNAME records if you append "cname" at the end of the command.
      # I assume the A record to always be printed on the last line.
      ctx.execute
        cmd: "dig #{ctx.config.host}. +short"
        code_skipped: 1
      , (err, executed, stdout, stderr) ->
        if err
          next err
        else unless ipRegex.test stdout.split(/\s+/).shift()
          ctx.log "Invalid IP #{stdout.trim()}"
          next null, 'WARNING'
        else
         next null, false

## DNS Reverse Lookup

Check reverse DNS lookup using the configured DNS configuration present inside
"/etc/resolv.conf". Internally, the exectuted command uses "dig".

    exports.push name: 'Network # DNS Reverse Lookup', handler: (ctx, next) ->
      ctx.execute
        cmd: "dig -x #{ctx.config.ip} +short"
        code_skipped: 1
      , (err, executed, stdout) ->
        if err
          next err
        else if "#{ctx.config.host}." isnt stdout.trim()
          ctx.log "Invalid host #{stdout.trim()}"
          next null, 'WARNING'
        else
         next null, false

## System Forward Lookup

Check forward DNS lookup using the system configuration which take into account
the local configuration present inside "/etc/hosts". Internally, the exectuted
command uses "getent".

    exports.push name: 'Network # System Forward Lookup', handler: (ctx, next) ->
      ctx.execute
        cmd: "getent hosts #{ctx.config.host}"
        code_skipped: 2
      , (err, valid, stdout, stderr) ->
        return next err if err
        return next null, 'WARNING' if not valid
        [ip, fqdn] = stdout.split(/\s+/).filter( (entry) -> entry)
        next null, if ip is ctx.config.ip and fqdn is ctx.config.host then false else 'WARNING'

## System Reverse Lookup

Check forward DNS lookup using the system configuration which take into account
the local configuration present inside "/etc/hosts". Internally, the exectuted
command uses "getent".

    exports.push name: 'Network # System Reverse Lookup', handler: (ctx, next) ->
      ctx.execute
        cmd: "getent hosts #{ctx.config.ip}"
        code_skipped: 2
      , (err, valid, stdout) ->
        return next err if err
        return next null, 'WARNING' if not valid
        [ip, fqdn] = stdout.split(/\s+/).filter( (entry) -> entry)
        next null, if ip is ctx.config.ip and fqdn is ctx.config.host then false else 'WARNING'

## Hostname

Read the server hostname and check it matches the expected FQDN. Internally, 
the executed command is `hostname --fqdn`.

    exports.push name: 'Network # Hostname', handler: (ctx, next) ->
      ctx.execute
        cmd: "hostname --fqdn"
      , (err, _, stdout) ->
        return next err if err
        next null, if stdout.trim() is ctx.config.host then false else 'WARNING'



