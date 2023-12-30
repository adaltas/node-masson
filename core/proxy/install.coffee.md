
# Proxy Install

    export default header: 'Proxy Install', handler: ({options}) ->

## System

      @file
        header: 'System'
        if: options.system
        target: options.system
        content: [
          "export http_proxy=#{options.http_proxy}"
          "export https_proxy=#{options.https_proxy}" if options.https_proxy
        ].join '\n'
        eof: true
