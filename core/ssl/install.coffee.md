
# SSL Install 

    module.exports = header: 'SSL Install', handler: ({options}) ->

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

## JKS

      @service
        header: 'OpenJDK'
        if: !options.truststore.disabled or !options.keystore.disabled
        name: 'java-1.8.0-openjdk-devel'
      # Client: import CA certificate
      @java.keystore_add
        header: 'Truststore'
        disabled: options.truststore.disabled
        keystore: options.truststore.target
        storepass: options.truststore.password
        caname: options.truststore.caname
        cacert: options.cacert.source
        local: options.cacert.local
        mode: 0o0644
        parent: mode: 0o0644
      # Server: import CA certificate, private and public keys
      @java.keystore_add
        header: 'Keystore'
        disabled: options.keystore.disabled
        keystore: options.keystore.target
        storepass: options.keystore.password
        caname: options.keystore.caname
        cacert: options.cacert.source
        key: options.key.source
        cert: options.cert.source
        keypass: options.keystore.keypass
        name: options.keystore.name
        local: options.cert.local
        mode: 0o0600
        parent: mode: 0o0644
