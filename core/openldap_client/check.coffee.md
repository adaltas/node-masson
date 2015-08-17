
# OpenLDAP Client

    exports = module.exports = []
    exports.push 'masson/bootstrap'
    exports.push 'masson/core/openldap_client/wait'
    exports.push require('./index').configure

    exports.push name: 'OpenLDAP Client # Check Search', label_true: 'CHECKED', handler: (ctx, next) ->
      {suffix, root_dn, root_password} = ctx.config.openldap_client
      return next() unless suffix
      ctx.execute
        cmd: "ldapsearch -x -D #{root_dn} -w #{root_password} -b '#{suffix}'"
      , (err, executed) ->
        next err, true
