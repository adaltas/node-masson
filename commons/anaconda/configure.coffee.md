
# Anaconda Configure

    module.exports = handler: ->
      anaconda = @config.anaconda ?= {}
      anaconda.build_dir ?= '/tmp/anaconda'
      anaconda.install_dir ?= '/opt'
      anaconda.version ?= '2.4.1'
      anaconda.source ?= "https://3230d63b5fc54e62148e-c95ac804525aac4b6dba79b00b39d1d3.ssl.cf1.rackcdn.com/Anaconda3-#{anaconda.version}-Linux-x86_64.sh"
      anaconda.archive ?= "#{@config.mecano.cache_dir or '.'}/anaconda3.tar.xz"
