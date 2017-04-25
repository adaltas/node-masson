
# SASLAuthd Stop

    module.exports = header: 'SASLAuthd Stop', timeout: -1, label_true: 'STOPPED', handler: ->
        @service.stop
          name: 'saslauthd'
