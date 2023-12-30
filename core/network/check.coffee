
ipRegex = /^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$/

export default
  metadata:
    header: 'Network Check'
  handler: ->
    @system.execute
      header: 'DNS Forward Lookup'
      cmd: "dig #{@config.host}. +short"
      code_skipped: 1
      shy: true
    , (err, executed, stdout, stderr) ->
      throw err if err
      unless ipRegex.test stdout.split(/\s+/).shift()
        @log "[WARN, masson `dig host`] Invalid returned IP #{stdout.trim()}"
        # next null, 'WARNING'
    @system.execute
      header: 'DNS Reverse Lookup'
      cmd: "dig -x #{@config.ip} +short"
      code_skipped: 1
      shy: true
    , (err, executed, stdout) ->
      throw err if err
      if "#{@config.host}." isnt stdout.trim()
        @log "[WARN, masson `dig ip`] Invalid returned host #{stdout.trim()}"
        # next null, 'WARNING'
    @system.execute
      header: 'System Forward Lookup'
      cmd: "getent hosts #{@config.host}"
      code_skipped: 2
      shy: true
    , (err, valid, stdout, stderr) ->
      throw err if err
      @log "[WARN, masson `getent host`] Invalid host #{stdout.trim()}" if not valid
      # return next null, 'WARNING' if not valid
      [ip, fqdn] = stdout.split(/\s+/).filter( (entry) -> entry)
      @log "[WARN, masson `getent host`] Invalid host #{@config.host}" if ip isnt @config.ip or fqdn isnt @config.host
    @system.execute
      header: 'System Reverse Lookup'
      cmd: "getent hosts #{@config.ip}"
      code_skipped: 2
      shy: true
    , (err, valid, stdout) ->
      throw err if err
      @log "[WARN, masson `getent host`] Invalid ip #{stdout.trim()}" if not valid
      # return next null, 'WARNING' if not valid
      [ip, fqdn] = stdout.split(/\s+/).filter( (entry) -> entry)
      @log "[WARN, masson `getent host`] Invalid ip #{@config.ip}" if ip isnt @config.ip or fqdn isnt @config.host
      # next null, if ip is @config.ip and fqdn is @config.host then false else 'WARNING'
    @system.execute
      header: 'Hostname'
      cmd: 'hostname --fqdn'
      shy: true
    , (err, _, stdout) ->
      throw err if err
      @log "[WARN, masson `getent host`] Invalid hostname" if stdout.trim() isnt @config.host
      # next null, if stdout.trim() is @config.host then false else 'WARNING'
