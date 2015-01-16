
# Kerberos Server Status

    exports = module.exports = []
    exports.push 'masson/bootstrap'

    exports.push name: 'Kerberos Server # Status kadmin', label_true: 'STARTED', label_false: 'STOPPED', handler: (ctx, next) ->
      ctx.execute
        cmd: "service kadmin status"
        code_skipped: 3
      , next

    exports.push name: 'Kerberos Server # Status krb5kdc', label_true: 'STARTED', label_false: 'STOPPED', handler: (ctx, next) ->
      ctx.execute
        cmd: "service krb5kdc status"
        code_skipped: 3
      , next
