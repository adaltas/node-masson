
# Kerberos Server Status

    exports = module.exports = []
    exports.push 'masson/bootstrap'

    exports.push name: 'Kerberos Server # Status kadmin', handler: (ctx, next) ->
      ctx.execute
        cmd: "service kadmin status"
        code_skipped: 3
      , (err, started) ->
        next err, if started then 'STARTED' else 'STOPPED'

    exports.push name: 'Kerberos Server # Status krb5kdc', handler: (ctx, next) ->
      ctx.execute
        cmd: "service krb5kdc status"
        code_skipped: 3
      , (err, started) ->
        next err, if started then 'STARTED' else 'STOPPED'
