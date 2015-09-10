
# Cloud9

    exports = module.exports = []
    exports.push 'masson/bootstrap'
    exports.push 'masson/core/yum'
    exports.push 'masson/commons/git'
    exports.push 'masson/commons/nodejs'

## Configuration

    exports.configure = (ctx) ->
      ctx.config.cloud9 ?= {}
      ctx.config.cloud9.path ?= '/usr/lib/cloud9'
      ctx.config.cloud9.github ?= 'https://github.com/ajaxorg/cloud9.git'
      ctx.config.cloud9.proxy ?= ctx.config.proxy

## Installation

    exports.push name: 'Cloud9 # Install', handler: ->
      {proxy, github}} = @config.cloud9

Install libxml2

      @service
        name: 'libxml2-devel'

Install SM plugin manager using NPM

      @execute
        cmd: 'npm install -g sm'

Download source code from github

      @git
        source: github
        destination: "/usr/lib/#{path}"

Run package installation

      # TODO: detect previous install of sm
      @execute
        cmd: "sm install"
        cwd: "/usr/lib/cloud9"
