
# OpenLDAP Client

    exports = module.exports = []
    exports.push 'masson/bootstrap'
    exports.push require('./index').configure

    exports.push name: 'OpenLDAP Client # Check Search', callback: (ctx, next) ->
      {suffix, root_dn, root_password} = ctx.config.openldap_client
      return next() unless suffix
      ctx.execute
        cmd: "ldapsearch -x -D #{root_dn} -w #{root_password} -b '#{suffix}'"
      , (err, executed) ->
        next err, true