
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

## Safe krb5 configuration

    module.exports.safe_etc_krb5_conf = safe_etc_krb5_conf = (etc_krb5_conf) ->
      etc_krb5_conf = krb5_server.safe_etc_krb5_conf etc_krb5_conf
      for realm, config of etc_krb5_conf.realms
        delete config.database_module
      delete etc_krb5_conf.dbmodules
      etc_krb5_conf

## Module Dependencies

    misc = require 'nikita/lib/misc'
    krb5_server = require '../krb5_server'
