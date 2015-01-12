
# RAR

    url = require 'url'
    exports = module.exports = []
    exports.push 'masson/bootstrap'
    exports.push require('../core/proxy').configure

    exports.push (ctx) ->
      ctx.config.rar ?= {}
      ctx.config.rar.proxy = ctx.config.proxy.http_proxy if typeof ctx.config.rar.proxy is 'undefined'
      ctx.config.rar ?= {}
      ctx.config.rar.rar_url ?= 'http://apt.sw.be/redhat/el6/en/x86_64/rpmforge/RPMS/rar-3.8.0-1.el6.rf.x86_64.rpm'
      ctx.config.rar.unrar_url ?= 'http://apt.sw.be/redhat/el6/en/x86_64/rpmforge/RPMS/unrar-4.0.7-1.el6.rf.x86_64.rpm'

    exports.push name: 'Rar # install rar', callback: (ctx, next) ->
      {proxy, rar_url} = ctx.config.rar
      ctx.execute
        cmd: "which rar"
        code_skipped: 1
      , (err, installed) ->
        return next err if err
        return next null, ctx.PASS if installed
        u = url.parse rar_url
        ctx[if u.protocol is 'http:' then 'download' else 'upload']
          source: rar_url
          destination: '/tmp/rar.rpm'
          proxy: proxy
          binary: true
        , (err, downloaded) ->
          return next err if err
          ctx.execute
            cmd: "rpm -Uvh /tmp/rar.rpm"
          , (err, executed) ->
            return next err if err
            ctx.remove destination: '/tmp/rar.rpm', (err, removed) ->
              next null, ctx.OK

    exports.push name: 'Rar # install unrar', callback: (ctx, next) ->
      {proxy, unrar_url} = ctx.config.rar
      ctx.execute
        cmd: "which unrar"
        code_skipped: 1
      , (err, installed) ->
        return next err if err
        return next null, ctx.PASS if installed
        u = url.parse unrar_url
        ctx[if u.protocol is 'http:' then 'download' else 'upload']
          source: unrar_url
          destination: '/tmp/unrar.rpm'
          proxy: proxy
          binary: true
        , (err, downloaded) ->
          return next err if err
          ctx.execute
            cmd: "rpm -Uvh /tmp/unrar.rpm"
          , (err, executed) ->
            return next err if err
            ctx.remove destination: '/tmp/unrar.rpm', (err, removed) ->
              next null, ctx.OK
