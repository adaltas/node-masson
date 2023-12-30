
# Krb5 Client

    export default
      deps:
        krb5_server: module: 'masson/core/krb5_server'
        ntp: module: 'masson/core/ntp'
        ssh: module: 'masson/core/ssh'
      configure:
        'masson/core/krb5_client/configure'
      commands:
        install: [
          'masson/core/krb5_client/install'
        ]

## Module Dependencies

    misc = require '@nikitajs/core/lib/misc'
    krb5_server = require '../krb5_server'
