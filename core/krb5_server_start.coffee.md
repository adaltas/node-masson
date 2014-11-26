
# Kerberos Server Start

    module.exports = []
    module.exports.push 'masson/bootstrap'

    module.exports.push name: 'Kerberos Server # Start kadmin', callback: (ctx, next) ->
      ctx.service
        srv_name: 'kadmin'
        action: 'start'
      , next

    module.exports.push name: 'Kerberos Server # Start krb5kdc', callback: (ctx, next) ->
      ctx.service
        srv_name: 'krb5kdc'
        action: 'start'
      , next
