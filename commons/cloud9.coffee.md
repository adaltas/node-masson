
# Cloud9

    exports = module.exports = []
    exports.push 'masson/bootstrap'
    exports.push 'masson/core/yum'
    exports.push 'masson/commons/git'
    exports.push 'masson/commons/nodejs'

    exports.push (ctx) ->
      ctx.config.cloud9 ?= {}
      ctx.config.cloud9.path ?= '/usr/lib/cloud9'
      ctx.config.cloud9.github ?= 'https://github.com/ajaxorg/cloud9.git'
      ctx.config.cloud9.proxy ?= ctx.config.proxy

    exports.push name: 'Cloud9 # libxml2', callback: (ctx, next) ->
      {proxy} = ctx.config.cloud9
      return next() if proxy
      ctx.service
        name: 'libxml2-devel'
      , next

    exports.push name: 'Cloud9 # SM', callback: (ctx, next) ->
      {proxy} = ctx.config.cloud9
      return next() if proxy
      ctx.execute
        cmd: 'npm install -g sm'
      , next

    exports.push name: 'Cloud9 # Git', callback: (ctx, next) ->
      {proxy, path, github} = ctx.config.cloud9
      return next() if proxy
      ctx.git
        source: github
        destination: "/usr/lib/#{path}"
      , next

    exports.push name: 'Cloud9 # Install', callback: (ctx, next) ->
      {proxy} = ctx.config.cloud9
      return next() if proxy
      # TODO: detect previous install of sm
      ctx.execute
        cmd: "sm install"
        cwd: "/usr/lib/cloud9"
      , next


