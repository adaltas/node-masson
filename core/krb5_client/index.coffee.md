
# Krb5 Client

    module.exports =
      use:
        krb5_server: 'masson/core/krb5_server'
        ntp: 'masson/core/ntp'
        ssh: 'masson/core/ssh'
      configure:
        'masson/core/krb5_client/configure'
      commands:
        install:
          'masson/core/krb5_client/install'

## Module Dependencies

    misc = require 'nikita/lib/misc'
    krb5_server = require '../krb5_server'
