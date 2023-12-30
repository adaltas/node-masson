
# chrony Install

    export default header: 'chrony Install', handler: ({options}) ->

## Package

      @service
        name: 'chrony'
        srv_name: 'chronyd'
        chk_name: 'chronyd'
        startup: true

## Configuration

The offline keyword indicates that the servers start in an offline state, and
that they should not be contacted until chronyd receives notification from
chronyc that the link to the internet is present. 

      @file
        header: 'Conf'
        if: options.config
        target: options.conf_file
        content: options.config
        eof: true
      @service.restart
        name: 'chronyd'
        if: -> @status -1
