
# Kerberos Server Stop

    module.exports = []
    module.exports.push 'masson/bootstrap'

    module.exports.push name: 'Kerberos Server # Stop kadmin', callback: (ctx, next) ->
      ctx.service
        srv_name: 'kadmin'
        action: 'stop'
      , next

    module.exports.push name: 'Kerberos Server # Stop krb5kdc', callback: (ctx, next) ->
      ctx.service
        srv_name: 'krb5kdc'
        action: 'stop'
      , next
