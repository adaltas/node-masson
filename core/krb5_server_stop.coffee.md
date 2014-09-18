
# Kerberos Server Stop

    module.exports = []
    module.exports.push 'masson/bootstrap/'

    module.exports.push name: 'Kerberos Server # Stop kadmin', callback: (ctx, next) ->
      ctx.service
        srv_name: 'kadmin'
        action: 'stop'
      , (err, stoped) ->
        next err, if stoped then ctx.OK else ctx.PASS

    module.exports.push name: 'Kerberos Server # Stop krb5kdc', callback: (ctx, next) ->
      ctx.service
        srv_name: 'krb5kdc'
        action: 'stop'
      , (err, stoped) ->
        next err, if stoped then ctx.OK else ctx.PASS
