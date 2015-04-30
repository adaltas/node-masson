
# Kerberos Server Stop

    exports = module.exports = []
    exports.push 'masson/bootstrap'

    exports.push name: 'Kerberos Server # Stop kadmin', label_true: 'STOPPED', handler: (ctx, next) ->
      ctx.service
        srv_name: 'kadmin'
        action: 'stop'
      , next

    exports.push name: 'Kerberos Server # Stop krb5kdc', label_true: 'STOPPED', handler: (ctx, next) ->
      ctx.service
        srv_name: 'krb5kdc'
        action: 'stop'
      , next
