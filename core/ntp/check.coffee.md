
## Check

This action compare the date on the remote server with the one where Masson is
being exectued. If the gap is greater than the one defined by the "ntp.lag"
property, the `ntpd` daemon is stop, the `ntpdate` command is used to
synchronization the date and the `ntpd` daemon is finally restarted.

    module.exports =
      header: 'NTP # Check'
      label_true: 'CHECKED'
      unless: [
         -> @config.ntp.servers[0] is @config.host
         -> @config.ntp.servers.length is 0
         -> @config.ntp.lag < 1
      ]
      handler: (options) ->
        # Here's good place to compare the date, maybe with the host maching:
        # if gap is greather than threehold, stop ntpd, ntpdate, start ntpd
        options.log "Synchronize the system clock with #{@config.ntp.servers[0]}"
        {lag} = @config.ntp
        current_lag = null
        @execute
          cmd: "date +%s"
        , (err, executed, stdout) ->
          throw err if err
          time = parseInt(stdout.trim(), 10) * 1000
          current_lag = Math.abs(new Date() - new Date(time))
        @call
          if: current_lag > lag
          handler: ->
            options.log "Lag greater than #{lag}ms: #{current_lag}ms"
            @service_stop
              name: 'ntpd'
              code_stopped: [1, 3]
            @execute
              cmd: "ntpdate #{@config.ntp.servers[0]}"
            @service_start
              name: 'ntpd'
              code_stopped: [1, 3]
