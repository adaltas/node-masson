
# Anaconda Configure

    module.exports = handler: ->
      anaconda = @config.anaconda ?= {}
      anaconda.tmp_dir ?= '/tmp'
      anaconda.install_dir ?= '/opt/anaconda'
      anaconda.version ?= '4.2.0'
      anaconda.python_version ?= '3'
      anaconda.source ?= "https://repo.continuum.io/archive/Anaconda#{anaconda.python_version}-#{anaconda.version}-Linux-x86_64.sh"
