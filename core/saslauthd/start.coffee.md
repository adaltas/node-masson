
# SASLAuthd Start

    module.exports = header: 'SASLAuthd Start', handler: ->
        @service.start
          name: 'saslauthd'
