
# Anaconda Configure

    module.exports = ->
      anaconda = @config.anaconda ?= {}
      anaconda.tmp_dir ?= '/tmp'
      anaconda.install_dir ?= '/opt/anaconda'
      anaconda.version ?= '4.3.0'
      anaconda.python_version ?= [2, 3]
      anaconda.python_version = [anaconda.python_version] unless Array.isArray anaconda.python_version
      anaconda.source ?= {}
      anaconda.source.python2 ?= "https://repo.continuum.io/archive/Anaconda2-#{anaconda.version}-Linux-x86_64.sh"
      anaconda.source.python3 ?= "https://repo.continuum.io/archive/Anaconda3-#{anaconda.version}-Linux-x86_64.sh"
