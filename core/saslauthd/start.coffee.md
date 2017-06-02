
# SASLAuthd Start

    module.exports = header: 'SASLAuthd Start', label_true: 'STARTED', handler: ->
        @service.start
          name: 'saslauthd'
