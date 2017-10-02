
# SASLAuthd Stop

    module.exports = header: 'SASLAuthd Stop', handler: ->
        @service.stop
          name: 'saslauthd'
