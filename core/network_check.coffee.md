
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

## Check DNS Forward Lookup

Check forward DNS lookup using the configured DNS configuration present inside
"/etc/resolv.conf". Internally, the exectuted command uses "dig".

    exports.push header: 'Network # Check DNS Forward Lookup', handler: (options) ->
      # I didnt find how to restrict dig to return only A records like it
      # does for CNAME records if you append "cname" at the end of the command.
      # I assume the A record to always be printed on the last line.
      @execute
        cmd: "dig #{@config.host}. +short"
        code_skipped: 1
        shy: true
      , (err, executed, stdout, stderr) ->
        throw err if err
        unless ipRegex.test stdout.split(/\s+/).shift()
          options.log "[WARN, masson `dig host`] Invalid returned IP #{stdout.trim()}"
          # next null, 'WARNING'

## DNS Reverse Lookup

Check reverse DNS lookup using the configured DNS configuration present inside
"/etc/resolv.conf". Internally, the exectuted command uses "dig".

    exports.push header: 'Network # DNS Reverse Lookup', handler: (options) ->
      @execute
        cmd: "dig -x #{@config.ip} +short"
        code_skipped: 1
        shy: true
      , (err, executed, stdout) ->
        throw err if err
        if "#{@config.host}." isnt stdout.trim()
          options.log "[WARN, masson `dig ip`] Invalid returned host #{stdout.trim()}"
          # next null, 'WARNING'

## Check System Forward Lookup

Check forward DNS lookup using the system configuration which take into account
the local configuration present inside "/etc/hosts". Internally, the exectuted
command uses "getent".

    exports.push header: 'Network # Check System Forward Lookup', handler: (options) ->
      @execute
        cmd: "getent hosts #{@config.host}"
        code_skipped: 2
        shy: true
      , (err, valid, stdout, stderr) ->
        throw err if err
        options.log "[WARN, masson `getent host`] Invalid host #{stdout.trim()}" if not valid
        # return next null, 'WARNING' if not valid
        [ip, fqdn] = stdout.split(/\s+/).filter( (entry) -> entry)
        options.log "[WARN, masson `getent host`] Invalid host #{@config.host}" if ip isnt @config.ip or fqdn isnt @config.host
        # next null, if ip is @config.ip and fqdn is @config.host then false else 'WARNING'

## Check System Reverse Lookup

Check forward DNS lookup using the system configuration which take into account
the local configuration present inside "/etc/hosts". Internally, the exectuted
command uses "getent".

    exports.push header: 'Network # Check System Reverse Lookup', handler: (options) ->
      @execute
        cmd: "getent hosts #{@config.ip}"
        code_skipped: 2
        shy: true
      , (err, valid, stdout) ->
        throw err if err
        options.log "[WARN, masson `getent host`] Invalid ip #{stdout.trim()}" if not valid
        # return next null, 'WARNING' if not valid
        [ip, fqdn] = stdout.split(/\s+/).filter( (entry) -> entry)
        options.log "[WARN, masson `getent host`] Invalid ip #{@config.ip}" if ip isnt @config.ip or fqdn isnt @config.host
        # next null, if ip is @config.ip and fqdn is @config.host then false else 'WARNING'

## Check Hostname

Read the server hostname and check it matches the expected FQDN. Internally, 
the executed command is `hostname --fqdn`.

    exports.push header: 'Network # Check Hostname', handler: ->
      @execute
        cmd: "hostname --fqdn"
        shy: true
      , (err, _, stdout) ->
        throw err if err
        options.log "[WARN, masson `getent host`] Invalid hostname" if stdout.trim() isnt @config.host
        # next null, if stdout.trim() is @config.host then false else 'WARNING'
