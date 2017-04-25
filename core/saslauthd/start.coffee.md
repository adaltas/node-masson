
# SASLAuthd Start

    module.exports = header: 'SASLAuthd Start', timeout: -1, label_true: 'STARTED', handler: ->
        @service.start
          name: 'saslauthd'
