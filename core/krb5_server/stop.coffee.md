
# Kerberos Server Stop

    exports = module.exports = []
    exports.push 'masson/bootstrap'

    exports.push name: 'Kerberos Server # Stop kadmin', handler: (ctx, next) ->
      ctx.service
        srv_name: 'kadmin'
        action: 'stop'
      , next

    exports.push name: 'Kerberos Server # Stop krb5kdc', handler: (ctx, next) ->
      ctx.service
        srv_name: 'krb5kdc'
        action: 'stop'
      , next
