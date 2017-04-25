
# NTP Check

    module.exports = header: 'NTP Check', handler: (options) ->
      @service.status 'ntpd', (err, status) ->
        throw err if err
        throw Error "Service Not Running: ntpd" unless status
