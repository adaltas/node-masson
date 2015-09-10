
# Krb5 Server Wait

Wait for all the Kerberos servers deployed by Masson.

## Preparation

    exports = module.exports = []
    exports.push 'masson/bootstrap'

## Wait TCP

    exports.push name: 'Krb5 Server # Wait TCP', timeout: -1, label_true: 'READY', handler: ->
      @wait_connect
        servers: for context in @contexts 'masson/core/krb5_server' #, require('./index').configure
          for realm, config of context.config.krb5.kdc_conf.realms
            host: context.config.host, port: config.kadmind_port or 749
