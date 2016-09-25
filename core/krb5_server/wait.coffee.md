
# Krb5 Server Wait

Wait for all the Kerberos servers deployed by Masson.

    module.exports = header: 'Krb5 Server Wait', timeout: -1, label_true: 'READY', handler: ->
      @connection.wait
        header: 'Kadmin'
        servers: for context in @contexts 'masson/core/krb5_server'
          for realm, config of context.config.krb5.kdc_conf.realms
            host: context.config.host, port: config.kadmind_port
