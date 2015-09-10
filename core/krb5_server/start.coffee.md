
# Kerberos Server Start

    exports = module.exports = []
    exports.push 'masson/bootstrap'
    exports.push 'masson/core/openldap_server/wait'

    exports.push name: 'Kerberos Server # Start kadmin', label_true: 'STARTED', handler: ->
      @service_start
        name: 'kadmin'

    exports.push name: 'Kerberos Server # Start krb5kdc', label_true: 'STARTED', handler: ->
      @service_start
        name: 'krb5kdc'
