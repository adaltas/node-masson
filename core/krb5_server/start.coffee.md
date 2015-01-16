
# Kerberos Server Start

    exports = module.exports = []
    exports.push 'masson/bootstrap'
    exports.push 'masson/core/openldap_server/wait'

    exports.push name: 'Kerberos Server # Start kadmin', handler: (ctx, next) ->
      ctx.service
        srv_name: 'kadmin'
        action: 'start'
      , next

    exports.push name: 'Kerberos Server # Start krb5kdc', handler: (ctx, next) ->
      ctx.service
        srv_name: 'krb5kdc'
        action: 'start'
      , next
