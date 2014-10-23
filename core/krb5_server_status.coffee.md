
# Kerberos Server Status

    module.exports = []
    module.exports.push 'masson/bootstrap/'

    module.exports.push name: 'Kerberos Server # Status kadmin', callback: (ctx, next) ->
      ctx.execute
        cmd: "service kadmin status"
        code_skipped: 3
      , (err, started) ->
        next err, if started then 'STARTED' else 'STOPPED'

    module.exports.push name: 'Kerberos Server # Status krb5kdc', callback: (ctx, next) ->
      ctx.execute
        cmd: "service krb5kdc status"
        code_skipped: 3
      , (err, started) ->
        next err, if started then 'STARTED' else 'STOPPED'
