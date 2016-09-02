
## Stop

Stop the `ntpd` daemon if it is running.

    module.exports = header: 'NTP Stop', label_true: 'STARTED', handler: ->
      @service.stop
        name: 'ntpd'
        code_stopped: [1, 3]
