
# NTP Check

    export default header: 'NTP Check', handler: ->

## Runing Sevrice

Ensure the "ntpd" service is up and running.

      @service.assert
        header: 'Service'
        name: 'ntp'
        srv_name: 'ntpd'
        installed: true
        started: true
