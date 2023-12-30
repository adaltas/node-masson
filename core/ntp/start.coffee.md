
# NTP Start

Start the `ntpd` daemon if it isnt yet running.

    export default header: 'NTP Start', handler: ({options}) ->

## Synchronization

Note, no NTPD server may be available yet, no solution at the moment
to wait for an available NTPD server.

      @system.execute
        header: 'Synchronization'
        cmd: """
        lag=`ntpdate -q #{options.servers[0]} | head -n 1| sed 's/.*offset -*\\([0-9]*\\).*/\\1/'`
        [ "$lag" -gt "#{Math.round(options.lag/1000)}" ] || exit 3
        """
        code_skipped: 3
      @call if: (-> @status -1), ->
        @service.stop 'ntpd'
        @system.execute "ntpdate #{options.servers[0]}"

## Service Start

      @service.start
        name: 'ntpd'
        code_stopped: [1, 3]
