
# Anaconda Python

Anaconda is a completely free Python distribution (including for commercial use
and redistribution). It includes more than 300 of the most popular Python packages
for science, math, engineering, and data analysis. See the packages included with
Anaconda and the Anaconda changelog.

    module.exports = []

## Configure

    module.exports.configure = (ctx) ->
      anaconda = ctx.config.anaconda ?= {}
      anaconda.build_dir ?= '/tmp/anaconda'
      anaconda.install_dir ?= '/opt'
      anaconda.version ?= '2.4.1'
      anaconda.source ?= "https://3230d63b5fc54e62148e-c95ac804525aac4b6dba79b00b39d1d3.ssl.cf1.rackcdn.com/Anaconda3-#{anaconda.version}-Linux-x86_64.sh"
      anaconda.archive ?= "#{@config.mecano.cache_dir or '.'}/anaconda3.tar.xz"

## Commands

    module.exports.push commands: 'install', modules: 'masson/commons/anaconda/install'

    module.exports.push commands: 'prepare', modules: 'masson/commons/anaconda/prepare'

