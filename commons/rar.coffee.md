
# RAR

    exports = module.exports = []
    exports.push 'masson/bootstrap'

## Configure

    exports.configure (ctx) ->
      require('../core/proxy').configure ctx
      ctx.config.rar ?= {}
      ctx.config.rar.proxy = ctx.config.proxy.http_proxy if typeof ctx.config.rar.proxy is 'undefined'
      ctx.config.rar ?= {}
      ctx.config.rar.rar_url ?= 'http://apt.sw.be/redhat/el6/en/x86_64/rpmforge/RPMS/rar-3.8.0-1.el6.rf.x86_64.rpm'
      ctx.config.rar.unrar_url ?= 'http://apt.sw.be/redhat/el6/en/x86_64/rpmforge/RPMS/unrar-4.0.7-1.el6.rf.x86_64.rpm'

    exports.push header: 'Rar # install rar', handler: ->
      {proxy, rar_url} = ctx.config.rar
      @download
        source: rar_url
        target: '/tmp/rar.rpm'
        proxy: proxy
        binary: true
        unless_exec: 'which rar'
      @execute
        cmd: "rpm -Uvh /tmp/rar.rpm"
        if: -> @status -1
      @remove
        target: '/tmp/rar.rpm'
        if: -> @status -2

    exports.push header: 'Rar # install unrar', handler: ->
      {proxy, unrar_url} = ctx.config.rar
      @download
        source: unrar_url
        target: '/tmp/unrar.rpm'
        proxy: proxy
        binary: true
        unless_exec: 'which unrar'
      @execute
        cmd: "rpm -Uvh /tmp/unrar.rpm"
      @remove
        target: '/tmp/unrar.rpm'

## Dependencies

    url = require 'url'
