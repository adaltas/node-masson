
# SSL Install 

    module.exports = header: 'SSL Install', handler: ->
      options = @config.ssl

## Upload Certicate Authority

      @file
        header: 'CA'
        if: options.cacert?.target
      , options.cacert

## Upload Public Certicate

      @file
        header: 'Cert'
        if: options.cert?.target
      , options.cert

## Upload Private Key

      @file
        header: 'Key'
        if: options.key?.target
      , options.key
