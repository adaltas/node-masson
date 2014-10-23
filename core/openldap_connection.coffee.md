---
title: 
layout: module
---
---
title: 
layout: module
---

    ldap = require 'ldapjs'
    module.exports = []
    module.exports.push 'masson/bootstrap/'

Connect
-------

Test the connection to the LDAP server. It creates two
connection, one using the admin credential available 
under `ctx.ldap_admin` and another one with the admin credential
available under `ctx.ldap_config`. Both objects are ldapjs 
client instance.

    module.exports.push module.exports.configure = (ctx, next) ->
      return next() if ctx.ldap_admin and ctx.ldap_config
      { root_dn, root_password,
        config_dn, config_password } = ctx.config.openldap_server
      admin = ->
        return config() if ctx.ldap_admin
        ctx.log 'Open admin connection'
        client = ldap.createClient url: "ldap://#{ctx.config.host}/"
        ctx.log 'Bind admin connection'
        client.bind "#{root_dn}", "#{root_password}", (err) ->
          return done err if err
          ctx.ldap_admin = client
          close = -> client.unbind()
          ctx.on 'error', close
          ctx.on 'end', close
          config()
      config = ->
        return done() if ctx.ldap_config
        ctx.log 'Open config connection'
        client = ldap.createClient url: "ldap://#{ctx.config.host}/"
        ctx.log 'Bind config connection'
        client.bind "#{config_dn}", "#{config_password}", (err) ->
          return done err if err
          ctx.ldap_config = client
          close = -> client.unbind()
          ctx.on 'error', close
          ctx.on 'end', close
          done()
      done = (err) ->
        next err, false
      admin()



