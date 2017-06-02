
# SASLAuthd Stop

    module.exports = header: 'SASLAuthd Stop', label_true: 'STOPPED', handler: ->
        @service.stop
          name: 'saslauthd'
