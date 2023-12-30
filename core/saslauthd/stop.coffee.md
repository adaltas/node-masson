
# SASLAuthd Stop

    export default header: 'SASLAuthd Stop', handler: ->
        @service.stop
          name: 'saslauthd'
