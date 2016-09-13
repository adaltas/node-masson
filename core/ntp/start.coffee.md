
# NTP Start

Start the `ntpd` daemon if it isnt yet running.

    module.exports = header: 'NTP Start', label_true: 'STARTED', handler: ->
      @service.start
        name: 'ntpd'
        code_stopped: [1, 3]
