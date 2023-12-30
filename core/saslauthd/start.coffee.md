
# SASLAuthd Start

    export default header: 'SASLAuthd Start', handler: ->
        @service.start
          name: 'saslauthd'
