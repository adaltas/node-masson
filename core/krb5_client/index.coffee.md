
# Krb5 Client

    module.exports = ->
      'configure': [
        'masson/core/krb5_client/configure'
      ]
      'install': [
        'masson/core/yum'
        'masson/core/ssh'
        'masson/core/ntp'
        'masson/core/krb5_server/wait'
        'masson/core/krb5_client/wait'
        'masson/core/krb5_client/install'
      ]

## Safe krb5 configuration

    module.exports.safe_etc_krb5_conf = safe_etc_krb5_conf = (etc_krb5_conf) ->
      etc_krb5_conf = krb5_server.safe_etc_krb5_conf etc_krb5_conf
      for realm, config of etc_krb5_conf.realms
        delete config.database_module
      delete etc_krb5_conf.dbmodules
      etc_krb5_conf

## Module Dependencies

    misc = require 'mecano/lib/misc'
    krb5_server = require '../krb5_server'
