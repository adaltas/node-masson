
# NTP Stop

Stop the `ntpd` daemon if it is running.

    export default header: 'NTP Stop', handler: ->
      @service.stop
        name: 'ntpd'
        code_stopped: [1, 3]
