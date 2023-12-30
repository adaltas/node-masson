
export default (service) ->
  options = service.options
  
  options.tmp_dir ?= '/tmp'
  options.install_dir ?= '/opt/anaconda'
  options.version ?= '4.3.0'
  options.python_version ?= [2, 3]
  options.python_version = [options.python_version] unless Array.isArray options.python_version
  options.source ?= {}
  options.source.python2 ?= "https://repo.continuum.io/archive/Anaconda2-#{options.version}-Linux-x86_64.sh"
  options.source.python3 ?= "https://repo.continuum.io/archive/Anaconda3-#{options.version}-Linux-x86_64.sh"
