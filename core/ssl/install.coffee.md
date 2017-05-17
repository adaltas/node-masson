
# SSL Install 

    module.exports = header: 'SSL Install', handler: ->
      options = @config.ssl

## Upload Certicate Authority

      @file.download
        header: 'CA'
        if: options.cacert?.target
      , options.cacert

## Upload Public Certicate

      @file.download
        header: 'Cert'
        if: options.cert?.target
      , options.cert

## Upload Private Key

      @file.download
        header: 'Key'
        if: options.key?.target
      , options.key
